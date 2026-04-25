-- ============================================================================
-- Migration 0022 — Anonymity redaction + moderation status
-- ============================================================================
-- Addresses DATABASE_REVIEW findings §1, §2, §3.
--
-- Problems fixed:
--   • Anonymous kudos leaked `sender_id` to all authenticated users.
--   • Anonymous kudos leaked sender↔recipient pairing via `kudo_recipients`.
--   • No moderation status on `kudos` → no way to soft-hide spam content.
--
-- Strategy:
--   1. Add `kudo_status` enum + `kudos.status` column (default 'active').
--   2. Create `kudos_feed` view with CASE-based sender redaction AND a
--      status filter (non-authors see only 'active'; authors see their own).
--   3. Revoke direct SELECT on `public.kudos` from `authenticated`; force
--      the client to read through the view.
--   4. Tighten `kudo_recipients_select` to hide anonymous pairings.
--   5. Add `kudo_moderation_events` audit table.
--   6. Refresh `kudos_with_stats` to wrap `kudos_feed`.
--
-- Rollback: see 0022_rollback.sql (not included here — generate at apply time
-- if needed; drop the new view, column, policy changes, and audit table in
-- reverse order).
-- ============================================================================

BEGIN;

-- ----------------------------------------------------------------------------
-- 1. Moderation status enum + column
-- ----------------------------------------------------------------------------

CREATE TYPE public.kudo_status AS ENUM ('active', 'soft_hidden', 'spam');

ALTER TABLE public.kudos
  ADD COLUMN status public.kudo_status NOT NULL DEFAULT 'active';

CREATE INDEX kudos_status_created_at
  ON public.kudos (status, created_at DESC);

-- ----------------------------------------------------------------------------
-- 2. kudos_feed — anonymity-redacted, status-filtered read surface
--
-- Every client (web + iOS) must switch SELECT from `public.kudos` → this view.
-- ----------------------------------------------------------------------------

CREATE OR REPLACE VIEW public.kudos_feed
WITH (security_invoker = true) AS
SELECT
  k.id,
  k.title,
  k.body,
  k.is_anonymous,
  k.anonymous_alias,
  k.status,
  k.created_at,
  -- Redact sender identity for anonymous kudos when the viewer is NOT the author.
  CASE
    WHEN k.is_anonymous AND k.sender_id <> auth.uid()
    THEN NULL
    ELSE k.sender_id
  END AS sender_id
FROM public.kudos k
WHERE
  -- Non-authors see only 'active' rows; authors see their own kudos in any status.
  k.status = 'active'
  OR k.sender_id = auth.uid();

COMMENT ON VIEW public.kudos_feed IS
  'Read surface for kudos. Redacts sender_id for anonymous rows when the viewer '
  'is not the author, and filters out soft_hidden/spam rows for non-authors. '
  'All clients MUST read via this view — public.kudos is revoked from `authenticated`.';

GRANT SELECT ON public.kudos_feed TO authenticated;

-- ----------------------------------------------------------------------------
-- 3. Revoke direct SELECT on public.kudos from clients
--
-- The SECURITY DEFINER functions (create_kudo, open_secret_box, etc.) still
-- have full access because they run with the function owner's privileges.
-- service_role also retains full access.
-- ----------------------------------------------------------------------------

-- Drop the permissive select policy first
DROP POLICY IF EXISTS kudos_select_authenticated ON public.kudos;

-- Revoke the privilege (RLS policies are ANDed with table privileges, so
-- revoking the privilege is the most direct guard)
REVOKE SELECT ON public.kudos FROM authenticated;

-- ----------------------------------------------------------------------------
-- 4. Tighten kudo_recipients SELECT policy
--
-- Non-author viewers of an anonymous kudo should not discover the recipient
-- via this junction table. Rule:
--   • If the kudo is NOT anonymous → anyone authenticated can read the row.
--   • If the kudo IS anonymous → only the author or the recipient can read.
-- ----------------------------------------------------------------------------

DROP POLICY IF EXISTS kudo_recipients_select ON public.kudo_recipients;

CREATE POLICY kudo_recipients_select ON public.kudo_recipients
  FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1
      FROM public.kudos k
      WHERE k.id = kudo_recipients.kudo_id
        AND (
          k.is_anonymous = false
          OR k.sender_id     = auth.uid()
          OR kudo_recipients.recipient_id = auth.uid()
        )
    )
  );

-- ----------------------------------------------------------------------------
-- 5. Update kudos_with_stats to wrap kudos_feed (so stats inherit filtering)
-- ----------------------------------------------------------------------------

DROP VIEW IF EXISTS public.kudos_with_stats;

CREATE OR REPLACE VIEW public.kudos_with_stats
WITH (security_invoker = true) AS
SELECT
  f.*,
  COALESCE(h.cnt, 0) AS hearts_count
FROM public.kudos_feed f
LEFT JOIN (
  SELECT kudo_id, COUNT(*)::int AS cnt
  FROM public.kudo_hearts
  GROUP BY kudo_id
) h ON h.kudo_id = f.id;

GRANT SELECT ON public.kudos_with_stats TO authenticated;

-- ----------------------------------------------------------------------------
-- 6. Moderation audit table
-- ----------------------------------------------------------------------------

CREATE TABLE public.kudo_moderation_events (
  id            uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  kudo_id       uuid        NOT NULL REFERENCES public.kudos(id) ON DELETE CASCADE,
  prev_status   public.kudo_status NOT NULL,
  new_status    public.kudo_status NOT NULL,
  criterion     text,                                  -- free text or slug of KudosSpamCriterion
  actor         text,                                  -- 'system' | 'admin:<uuid>'
  created_at    timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX kudo_moderation_events_kudo_id
  ON public.kudo_moderation_events (kudo_id, created_at DESC);

ALTER TABLE public.kudo_moderation_events ENABLE ROW LEVEL SECURITY;

-- Authors can read their own kudos' moderation history
CREATE POLICY kudo_moderation_events_select_author ON public.kudo_moderation_events
  FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.kudos k
      WHERE k.id = kudo_moderation_events.kudo_id
        AND k.sender_id = auth.uid()
    )
  );

-- Inserts are backend-only via service_role (no policy granted).

COMMIT;
