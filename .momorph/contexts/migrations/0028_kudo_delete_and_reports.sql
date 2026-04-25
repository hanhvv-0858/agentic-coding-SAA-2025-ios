-- ============================================================================
-- Migration 0028 — Optional: Kudo delete (author) + kudo_reports table
-- ============================================================================
-- Addresses DATABASE_REVIEW findings §16 and notes from [view-kudo.md].
--
-- Problems fixed:
--   • view-kudo.md specifies action-buttons with a capability matrix:
--     Owner → Edit/Delete, Non-owner → Share/Report. The database currently
--     has no DELETE policy on `kudos` and no `kudo_reports` table.
--
-- Strategy:
--   • Add a self-DELETE policy on `kudos` (authors can delete their own).
--   • Add `kudo_reports` table so non-owners can flag content for admin
--     review (feeding into N7 `admin_review_request`).
--
-- Product-dependent — only apply this migration if the iOS design confirms
-- the Owner / Non-owner action-button matrix. If v1 is ship-without-edit
-- (immutability strictness), skip §1 of this migration and only apply §2.
-- ============================================================================

BEGIN;

-- ----------------------------------------------------------------------------
-- 1. Author can delete their own kudo
-- ----------------------------------------------------------------------------

CREATE POLICY kudos_delete_self ON public.kudos
  FOR DELETE TO authenticated
  USING (sender_id = auth.uid());

-- ----------------------------------------------------------------------------
-- 2. kudo_reports — community-driven moderation feed
-- ----------------------------------------------------------------------------

CREATE TABLE public.kudo_reports (
  id           uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  kudo_id      uuid        NOT NULL REFERENCES public.kudos(id) ON DELETE CASCADE,
  reporter_id  uuid        NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  reason_slug  text        NOT NULL,      -- free text or a KudosSpamCriterion enum slug
  note         text,                      -- optional extra context
  created_at   timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT kudo_reports_reason_nonempty CHECK (length(btrim(reason_slug)) > 0),
  CONSTRAINT kudo_reports_not_self CHECK (true)  -- we rely on RLS (see policy) for self-check
);

-- Index on kudo_id for admin review feed queries.
CREATE INDEX kudo_reports_kudo_id_created ON public.kudo_reports (kudo_id, created_at DESC);

-- Unique per (reporter, kudo) — a user can report a given kudo only once.
CREATE UNIQUE INDEX kudo_reports_reporter_kudo_unique
  ON public.kudo_reports (reporter_id, kudo_id);

ALTER TABLE public.kudo_reports ENABLE ROW LEVEL SECURITY;

-- Reporter can SELECT their own submitted reports.
CREATE POLICY kudo_reports_select_self ON public.kudo_reports
  FOR SELECT TO authenticated
  USING (reporter_id = auth.uid());

-- Reporter can INSERT a report on a kudo that isn't theirs.
CREATE POLICY kudo_reports_insert_non_self ON public.kudo_reports
  FOR INSERT TO authenticated
  WITH CHECK (
    reporter_id = auth.uid()
    AND NOT EXISTS (
      SELECT 1 FROM public.kudos k
      WHERE k.id = kudo_reports.kudo_id
        AND k.sender_id = auth.uid()
    )
  );

-- No UPDATE / DELETE for authenticated — only service_role + admins.

-- ----------------------------------------------------------------------------
-- 3. Optional: fire N7 on new report (admins only)
--
-- N7 is admin-facing, so iOS clients for non-admins should not receive it.
-- The simplest guard is a trigger that only notifies users with an admin
-- capability. This project doesn't yet have an `admin_roles` table; until
-- it does, N7 is left as a backend-only insertion (service_role) — which is
-- already the default, so no trigger is created here.
-- ----------------------------------------------------------------------------

COMMIT;
