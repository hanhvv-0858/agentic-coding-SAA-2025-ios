-- ============================================================================
-- Sun* Annual Awards 2025 — Consolidated Database Schema (post-iOS fixes)
-- ============================================================================
-- Snapshot of the public schema AFTER migrations 0001–0028. The 0022–0028
-- migration files were added during the iOS app planning to close gaps
-- surfaced in DATABASE_REVIEW.md (anonymity leak, moderation workflow,
-- server-authoritative secret-box opening, notifications inbox, awards
-- catalogue, length constraints, search index, hashtag lock-down, kudo
-- delete + reports).
--
-- This file is a CURRENT-STATE reference, not a replayable migration. See
-- .momorph/contexts/migrations/0022..0028_*.sql for the exact changes.
--
-- External dependencies (Supabase-managed):
--   * auth.users          — Supabase Auth
--   * storage.buckets     — Supabase Storage
--   * storage.objects     — Supabase Storage
--   * extension pgcrypto  — for gen_random_uuid()
--   * extension pg_trgm   — for trigram search (added in 0027)
-- ============================================================================

-- ============================================================================
-- ENUM TYPES
-- ============================================================================

CREATE TYPE public.honour_title AS ENUM (
  'Legend Hero',
  'Rising Hero',
  'Super Hero',
  'New Hero'
);

-- Added in migration 0022
CREATE TYPE public.kudo_status AS ENUM (
  'active',
  'soft_hidden',
  'spam'
);

-- Added in migration 0023
CREATE TYPE public.badge_kind AS ENUM (
  'revival',
  'touch_of_light',
  'stay_gold',
  'flow_to_horizon',
  'beyond_the_boundary',
  'root_further'
);

-- Added in migration 0024
CREATE TYPE public.notification_type AS ENUM (
  'kudos_received',
  'kudos_liked',
  'secret_box_granted',
  'level_up',
  'content_soft_hidden',
  'badge_collected',
  'admin_review_request'
);

-- Added in migration 0025
CREATE TYPE public.award_kind AS ENUM (
  'mvp',
  'best_manager',
  'signature_creator',
  'top_project',
  'top_project_leader',
  'top_talent'
);

-- ============================================================================
-- TABLES
-- ============================================================================

-- ----------------------------------------------------------------------------
-- departments — Sun* organisational unit registry.
-- ----------------------------------------------------------------------------
CREATE TABLE public.departments (
  id          uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  code        text        NOT NULL UNIQUE,
  name_vi     text        NOT NULL,
  name_en     text        NOT NULL,
  created_at  timestamptz NOT NULL DEFAULT now()
);

-- ----------------------------------------------------------------------------
-- profiles — Denormalised mirror of auth.users with department + honour tier.
-- Auto-provisioned on first sign-in via on_auth_user_created trigger.
-- ----------------------------------------------------------------------------
CREATE TABLE public.profiles (
  id             uuid                 PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email          text                 NOT NULL,
  display_name   text,
  avatar_url     text,
  department_id  uuid                 REFERENCES public.departments(id),
  honour_title   public.honour_title,
  created_at     timestamptz          NOT NULL DEFAULT now()
);

-- Added in migration 0027: trigram index for ILIKE searches used by
-- Search Sunner and the RecipientPickerSheet.
CREATE INDEX profiles_display_name_trgm
  ON public.profiles
  USING gin (display_name gin_trgm_ops);

-- ----------------------------------------------------------------------------
-- hashtags — Bilingual social-tagging vocabulary (admin-curated).
-- ----------------------------------------------------------------------------
CREATE TABLE public.hashtags (
  id          uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  slug        text        NOT NULL UNIQUE,
  label_vi    text        NOT NULL,
  label_en    text        NOT NULL,
  created_at  timestamptz NOT NULL DEFAULT now()
);

-- ----------------------------------------------------------------------------
-- kudos — Primary recognition record. `status` (0022) + length bounds (0026).
-- Authors can delete their own kudos (0028). Anonymity is redacted at read
-- time through public.kudos_feed; direct SELECT is revoked from authenticated
-- (see 0022).
-- ----------------------------------------------------------------------------
CREATE TABLE public.kudos (
  id                uuid               PRIMARY KEY DEFAULT gen_random_uuid(),
  sender_id         uuid               NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  body              text               NOT NULL,
  title             text,
  is_anonymous      boolean            NOT NULL DEFAULT false,
  anonymous_alias   text,
  status            public.kudo_status NOT NULL DEFAULT 'active',
  created_at        timestamptz        NOT NULL DEFAULT now(),

  CONSTRAINT kudos_anonymous_alias_pairing CHECK (
    (is_anonymous = false AND anonymous_alias IS NULL)
    OR (is_anonymous = true  AND char_length(btrim(anonymous_alias)) BETWEEN 2 AND 40)
  ),

  -- Length bounds (0026) — NOT VALID at creation; validate after legacy cleanup.
  CONSTRAINT kudos_body_length
    CHECK (char_length(btrim(body)) BETWEEN 30 AND 2000) NOT VALID,
  CONSTRAINT kudos_title_length
    CHECK (title IS NULL OR char_length(btrim(title)) BETWEEN 3 AND 80) NOT VALID
);

CREATE INDEX kudos_created_at_desc   ON public.kudos (created_at DESC);
CREATE INDEX kudos_status_created_at ON public.kudos (status, created_at DESC);

-- ----------------------------------------------------------------------------
-- kudo_recipients — Sender → recipient junction.
-- ----------------------------------------------------------------------------
CREATE TABLE public.kudo_recipients (
  kudo_id       uuid NOT NULL REFERENCES public.kudos(id)    ON DELETE CASCADE,
  recipient_id  uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  PRIMARY KEY (kudo_id, recipient_id)
);

-- ----------------------------------------------------------------------------
-- kudo_hashtags — Many-to-many junction (cap ≤5 enforced by 0026 trigger).
-- ----------------------------------------------------------------------------
CREATE TABLE public.kudo_hashtags (
  kudo_id     uuid NOT NULL REFERENCES public.kudos(id)    ON DELETE CASCADE,
  hashtag_id  uuid NOT NULL REFERENCES public.hashtags(id) ON DELETE CASCADE,
  PRIMARY KEY (kudo_id, hashtag_id)
);

CREATE INDEX kudo_hashtags_hashtag_id ON public.kudo_hashtags (hashtag_id);

-- ----------------------------------------------------------------------------
-- kudo_hearts — Idempotent like/heart toggle.
-- ----------------------------------------------------------------------------
CREATE TABLE public.kudo_hearts (
  kudo_id     uuid        NOT NULL REFERENCES public.kudos(id)    ON DELETE CASCADE,
  user_id     uuid        NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  created_at  timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (kudo_id, user_id)
);

CREATE INDEX kudo_hearts_user_id ON public.kudo_hearts (user_id);

-- ----------------------------------------------------------------------------
-- kudo_images — Up-to-5 image attachments per kudo.
-- ----------------------------------------------------------------------------
CREATE TABLE public.kudo_images (
  id          uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  kudo_id     uuid        NOT NULL REFERENCES public.kudos(id) ON DELETE CASCADE,
  url         text        NOT NULL,
  position    smallint    NOT NULL DEFAULT 0 CHECK (position BETWEEN 0 AND 4),
  created_at  timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX kudo_images_kudo_id_position ON public.kudo_images (kudo_id, position);

-- ----------------------------------------------------------------------------
-- kudo_moderation_events (0022) — Audit trail for kudos.status transitions.
-- Backend writes only; authors can read their own kudos' history.
-- ----------------------------------------------------------------------------
CREATE TABLE public.kudo_moderation_events (
  id           uuid               PRIMARY KEY DEFAULT gen_random_uuid(),
  kudo_id      uuid               NOT NULL REFERENCES public.kudos(id) ON DELETE CASCADE,
  prev_status  public.kudo_status NOT NULL,
  new_status   public.kudo_status NOT NULL,
  criterion    text,                                              -- free text or KudosSpamCriterion slug
  actor        text,                                              -- 'system' | 'admin:<uuid>'
  created_at   timestamptz        NOT NULL DEFAULT now()
);

CREATE INDEX kudo_moderation_events_kudo_id
  ON public.kudo_moderation_events (kudo_id, created_at DESC);

-- ----------------------------------------------------------------------------
-- kudo_reports (0028) — Community-driven moderation feed.
-- ----------------------------------------------------------------------------
CREATE TABLE public.kudo_reports (
  id           uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  kudo_id      uuid        NOT NULL REFERENCES public.kudos(id) ON DELETE CASCADE,
  reporter_id  uuid        NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  reason_slug  text        NOT NULL,                              -- KudosSpamCriterion enum slug or free text
  note         text,
  created_at   timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT kudo_reports_reason_nonempty CHECK (length(btrim(reason_slug)) > 0)
);

CREATE INDEX kudo_reports_kudo_id_created
  ON public.kudo_reports (kudo_id, created_at DESC);

-- One report per (reporter, kudo) — cannot spam-report the same kudo.
CREATE UNIQUE INDEX kudo_reports_reporter_kudo_unique
  ON public.kudo_reports (reporter_id, kudo_id);

-- ----------------------------------------------------------------------------
-- notifications (0024) — Per-recipient typed inbox.
-- Insert via SECURITY DEFINER triggers only; recipient may SELECT and UPDATE
-- read_at on their own rows.
-- ----------------------------------------------------------------------------
CREATE TABLE public.notifications (
  id            uuid                     PRIMARY KEY DEFAULT gen_random_uuid(),
  recipient_id  uuid                     NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  type          public.notification_type NOT NULL,
  payload       jsonb                    NOT NULL DEFAULT '{}'::jsonb,
  read_at       timestamptz,
  created_at    timestamptz              NOT NULL DEFAULT now()
);

CREATE INDEX notifications_recipient_created
  ON public.notifications (recipient_id, created_at DESC);

CREATE INDEX notifications_unread_partial
  ON public.notifications (recipient_id) WHERE read_at IS NULL;

-- ----------------------------------------------------------------------------
-- awards (0025) — Award catalogue (6 canonical kinds, bilingual).
-- ----------------------------------------------------------------------------
CREATE TABLE public.awards (
  kind              public.award_kind PRIMARY KEY,
  title_vi          text        NOT NULL,
  title_en          text        NOT NULL,
  description_vi    text        NOT NULL,
  description_en    text        NOT NULL,
  artwork_asset_key text        NOT NULL,
  display_order     smallint    NOT NULL,
  created_at        timestamptz NOT NULL DEFAULT now(),
  updated_at        timestamptz NOT NULL DEFAULT now()
);

CREATE UNIQUE INDEX awards_display_order ON public.awards (display_order);

-- ----------------------------------------------------------------------------
-- gift_redemptions — One physical-prize redemption per Sunner (UNIQUE user_id).
-- Backend-only writes.
-- ----------------------------------------------------------------------------
CREATE TABLE public.gift_redemptions (
  id           uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id      uuid        NOT NULL UNIQUE REFERENCES public.profiles(id) ON DELETE CASCADE,
  gift_name    text        NOT NULL,
  quantity     integer     NOT NULL DEFAULT 1 CHECK (quantity > 0),
  source       text        NOT NULL DEFAULT 'secret_box',
  redeemed_at  timestamptz NOT NULL DEFAULT now(),
  created_at   timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX gift_redemptions_redeemed_at_desc ON public.gift_redemptions (redeemed_at DESC);
CREATE INDEX gift_redemptions_user_id          ON public.gift_redemptions (user_id);

-- ----------------------------------------------------------------------------
-- secret_boxes (extended in 0023) — Per-Sunner box ledger with prize fields.
-- Opening goes through `public.open_secret_box()` RPC; direct UPDATE is
-- revoked from authenticated.
-- ----------------------------------------------------------------------------
CREATE TABLE public.secret_boxes (
  id               uuid               PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id          uuid               NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  opened_at        timestamptz,
  prize_type       text,                                              -- 'badge' | 'physical'
  badge_kind       public.badge_kind,
  prize_name       text,
  prize_asset_key  text,
  created_at       timestamptz        NOT NULL DEFAULT now(),

  CONSTRAINT secret_boxes_prize_type_domain
    CHECK (prize_type IS NULL OR prize_type IN ('badge', 'physical')),

  CONSTRAINT secret_boxes_prize_pairing CHECK (
    (opened_at IS NULL     AND prize_type IS NULL AND badge_kind IS NULL
                           AND prize_name IS NULL AND prize_asset_key IS NULL)
    OR
    (opened_at IS NOT NULL AND prize_type IS NOT NULL)
  ),

  CONSTRAINT secret_boxes_prize_shape CHECK (
    (prize_type IS NULL)
    OR (prize_type = 'badge'    AND badge_kind IS NOT NULL)
    OR (prize_type = 'physical' AND prize_name IS NOT NULL AND length(btrim(prize_name)) > 0)
  )
);

CREATE INDEX secret_boxes_user_opened ON public.secret_boxes (user_id, opened_at);

-- ============================================================================
-- VIEWS
-- ============================================================================

-- ----------------------------------------------------------------------------
-- kudos_feed (0022) — Anonymity-redacted, status-filtered read surface.
-- All clients read through this view; direct SELECT on public.kudos is revoked.
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
  CASE
    WHEN k.is_anonymous AND k.sender_id <> auth.uid() THEN NULL
    ELSE k.sender_id
  END AS sender_id
FROM public.kudos k
WHERE
  k.status = 'active'
  OR k.sender_id = auth.uid();

-- ----------------------------------------------------------------------------
-- kudos_with_stats (updated in 0022) — Hot-path feed view wrapping kudos_feed.
-- Inherits anonymity redaction + status filtering. `has_hearted` is computed
-- per-user at query time via an additional LEFT JOIN against kudo_hearts.
-- ----------------------------------------------------------------------------
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

-- ============================================================================
-- FUNCTIONS
-- ============================================================================

-- ----------------------------------------------------------------------------
-- handle_new_user() — Trigger: auto-provision profiles on first sign-in.
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.profiles (id, email, display_name, avatar_url)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(
      NEW.raw_user_meta_data ->> 'full_name',
      split_part(NEW.email, '@', 1)
    ),
    NEW.raw_user_meta_data ->> 'avatar_url'
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$;

-- ----------------------------------------------------------------------------
-- enforce_kudo_image_limit() — Hard-cap kudo images at 5.
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.enforce_kudo_image_limit()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  IF (SELECT COUNT(*) FROM public.kudo_images WHERE kudo_id = NEW.kudo_id) >= 5 THEN
    RAISE EXCEPTION 'kudo_images: each kudo may carry at most 5 images';
  END IF;
  RETURN NEW;
END;
$$;

-- ----------------------------------------------------------------------------
-- enforce_kudo_hashtag_limit() (0026) — Hard-cap kudo hashtags at 5.
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.enforce_kudo_hashtag_limit()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  IF (SELECT COUNT(*) FROM public.kudo_hashtags WHERE kudo_id = NEW.kudo_id) >= 5 THEN
    RAISE EXCEPTION 'kudo_hashtags: each kudo may carry at most 5 hashtags';
  END IF;
  RETURN NEW;
END;
$$;

-- ----------------------------------------------------------------------------
-- compute_honour_tier(uuid) — Thresholds 1/5/10/20.
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.compute_honour_tier(p_user_id uuid)
RETURNS public.honour_title
LANGUAGE sql
STABLE
AS $$
  WITH counts AS (
    SELECT COUNT(DISTINCT k.sender_id) AS distinct_senders
    FROM public.kudo_recipients kr
    JOIN public.kudos k ON k.id = kr.kudo_id
    WHERE kr.recipient_id = p_user_id
  )
  SELECT CASE
    WHEN distinct_senders = 0                 THEN NULL::public.honour_title
    WHEN distinct_senders BETWEEN 1  AND 4    THEN 'New Hero'::public.honour_title
    WHEN distinct_senders BETWEEN 5  AND 9    THEN 'Rising Hero'::public.honour_title
    WHEN distinct_senders BETWEEN 10 AND 19   THEN 'Super Hero'::public.honour_title
    ELSE                                            'Legend Hero'::public.honour_title
  END
  FROM counts;
$$;

REVOKE ALL    ON FUNCTION public.compute_honour_tier(uuid) FROM public;
GRANT  EXECUTE ON FUNCTION public.compute_honour_tier(uuid) TO authenticated, service_role;

-- ----------------------------------------------------------------------------
-- sync_recipient_honour() — Recompute honour tier on new kudo_recipients row.
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.sync_recipient_honour()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  new_tier public.honour_title;
BEGIN
  new_tier := public.compute_honour_tier(NEW.recipient_id);
  UPDATE public.profiles
    SET honour_title = new_tier
  WHERE id = NEW.recipient_id
    AND honour_title IS DISTINCT FROM new_tier;
  RETURN NEW;
END;
$$;

-- ----------------------------------------------------------------------------
-- create_kudo(...) — Atomic composer (unchanged since 0017).
-- ----------------------------------------------------------------------------
-- [Body omitted for brevity — see migration 0017. Signature: p_title, p_body,
-- p_is_anonymous, p_recipient_id, p_hashtag_slugs, p_image_paths,
-- p_anonymous_alias DEFAULT NULL. EXECUTE granted to `authenticated`.]

-- ----------------------------------------------------------------------------
-- open_secret_box() (0023) — Server-authoritative reveal.
-- Picks oldest unopened box FOR UPDATE SKIP LOCKED, assigns a random badge,
-- sets opened_at + prize fields. Returns the updated row.
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.open_secret_box()
RETURNS public.secret_boxes
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  uid         uuid := auth.uid();
  box         public.secret_boxes%ROWTYPE;
  pool        public.badge_kind[] := ARRAY[
    'revival', 'touch_of_light', 'stay_gold',
    'flow_to_horizon', 'beyond_the_boundary', 'root_further'
  ]::public.badge_kind[];
  chosen_kind public.badge_kind;
BEGIN
  IF uid IS NULL THEN
    RAISE EXCEPTION 'open_secret_box: not authenticated';
  END IF;

  SELECT * INTO box
  FROM public.secret_boxes
  WHERE user_id = uid AND opened_at IS NULL
  ORDER BY created_at ASC
  FOR UPDATE SKIP LOCKED
  LIMIT 1;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'open_secret_box: no_unopened_box_for_user';
  END IF;

  chosen_kind := pool[1 + floor(random() * array_length(pool, 1))::int];

  UPDATE public.secret_boxes
  SET opened_at       = now(),
      prize_type      = 'badge',
      badge_kind      = chosen_kind,
      prize_name      = NULL,
      prize_asset_key = 'badge_' || chosen_kind::text
  WHERE id = box.id
  RETURNING * INTO box;

  RETURN box;
END;
$$;

REVOKE ALL    ON FUNCTION public.open_secret_box() FROM public;
GRANT  EXECUTE ON FUNCTION public.open_secret_box() TO authenticated;

-- ----------------------------------------------------------------------------
-- maybe_grant_secret_box() (0023) — Trigger on kudo_hearts to mint boxes.
-- Rule: for each sender, every 5 hearts received on their kudos = 1 new box.
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.maybe_grant_secret_box()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  sender       uuid;
  lock_key     bigint;
  total_hearts int;
  total_boxes  int;
BEGIN
  SELECT k.sender_id INTO sender FROM public.kudos k WHERE k.id = NEW.kudo_id;
  IF sender IS NULL THEN RETURN NEW; END IF;

  lock_key := hashtextextended(sender::text, 42);
  PERFORM pg_advisory_xact_lock(lock_key);

  SELECT COUNT(*) INTO total_hearts
  FROM public.kudo_hearts h
  JOIN public.kudos       k ON k.id = h.kudo_id
  WHERE k.sender_id = sender;

  SELECT COUNT(*) INTO total_boxes FROM public.secret_boxes WHERE user_id = sender;

  IF (total_hearts / 5) > total_boxes THEN
    INSERT INTO public.secret_boxes (user_id) VALUES (sender);
  END IF;
  RETURN NEW;
END;
$$;

-- ----------------------------------------------------------------------------
-- notify_* (0024) — Six SECURITY DEFINER trigger functions that insert into
-- public.notifications on the corresponding parent events. Bodies omitted
-- here for brevity; see migration 0024 for the exact logic:
--   notify_kudos_received      (on kudo_recipients INSERT)
--   notify_kudos_liked         (on kudo_hearts    INSERT, liker ≠ sender)
--   notify_secret_box_granted  (on secret_boxes   INSERT, unopened)
--   notify_level_up            (on profiles       UPDATE OF honour_title, upward)
--   notify_content_soft_hidden (on kudos          UPDATE OF status → soft_hidden)
--   notify_badge_collected     (on gift_redemptions INSERT)
-- N7 `admin_review_request` is inserted by backend logic (service_role), not
-- by a trigger.
-- ----------------------------------------------------------------------------

-- ============================================================================
-- TRIGGERS
-- ============================================================================

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

CREATE TRIGGER kudo_images_limit
  BEFORE INSERT ON public.kudo_images
  FOR EACH ROW
  EXECUTE FUNCTION public.enforce_kudo_image_limit();

CREATE TRIGGER kudo_hashtags_limit
  BEFORE INSERT ON public.kudo_hashtags
  FOR EACH ROW
  EXECUTE FUNCTION public.enforce_kudo_hashtag_limit();

CREATE TRIGGER trg_sync_recipient_honour
  AFTER INSERT ON public.kudo_recipients
  FOR EACH ROW
  EXECUTE FUNCTION public.sync_recipient_honour();

CREATE TRIGGER trg_grant_secret_box_on_heart
  AFTER INSERT ON public.kudo_hearts
  FOR EACH ROW
  EXECUTE FUNCTION public.maybe_grant_secret_box();

CREATE TRIGGER trg_notify_kudos_received
  AFTER INSERT ON public.kudo_recipients
  FOR EACH ROW
  EXECUTE FUNCTION public.notify_kudos_received();

CREATE TRIGGER trg_notify_kudos_liked
  AFTER INSERT ON public.kudo_hearts
  FOR EACH ROW
  EXECUTE FUNCTION public.notify_kudos_liked();

CREATE TRIGGER trg_notify_secret_box_granted
  AFTER INSERT ON public.secret_boxes
  FOR EACH ROW
  EXECUTE FUNCTION public.notify_secret_box_granted();

CREATE TRIGGER trg_notify_level_up
  AFTER UPDATE OF honour_title ON public.profiles
  FOR EACH ROW
  EXECUTE FUNCTION public.notify_level_up();

CREATE TRIGGER trg_notify_content_soft_hidden
  AFTER UPDATE OF status ON public.kudos
  FOR EACH ROW
  EXECUTE FUNCTION public.notify_content_soft_hidden();

CREATE TRIGGER trg_notify_badge_collected
  AFTER INSERT ON public.gift_redemptions
  FOR EACH ROW
  EXECUTE FUNCTION public.notify_badge_collected();

-- ============================================================================
-- ROW-LEVEL SECURITY
-- ============================================================================

ALTER TABLE public.departments              ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.profiles                 ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.hashtags                 ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.kudos                    ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.kudo_recipients          ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.kudo_hashtags            ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.kudo_hearts              ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.kudo_images              ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.kudo_moderation_events   ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.kudo_reports             ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications            ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.awards                   ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.gift_redemptions         ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.secret_boxes             ENABLE ROW LEVEL SECURITY;

-- ---- departments ----------------------------------------------------------
CREATE POLICY departments_select_authenticated ON public.departments
  FOR SELECT TO authenticated USING (true);

-- ---- profiles -------------------------------------------------------------
CREATE POLICY profiles_select_authenticated ON public.profiles
  FOR SELECT TO authenticated USING (true);
CREATE POLICY profiles_insert_self ON public.profiles
  FOR INSERT TO authenticated WITH CHECK (id = auth.uid());
CREATE POLICY profiles_update_self ON public.profiles
  FOR UPDATE TO authenticated USING (id = auth.uid()) WITH CHECK (id = auth.uid());

-- ---- hashtags -------------------------------------------------------------
-- (0027) INSERT policy removed — hashtags are admin-curated (service_role).
CREATE POLICY hashtags_select_authenticated ON public.hashtags
  FOR SELECT TO authenticated USING (true);

-- ---- kudos ----------------------------------------------------------------
-- (0022) SELECT via kudos_feed view; direct SELECT revoked from authenticated.
REVOKE SELECT ON public.kudos FROM authenticated;
CREATE POLICY kudos_insert_self ON public.kudos
  FOR INSERT TO authenticated WITH CHECK (sender_id = auth.uid());
-- (0028) optional author-delete
CREATE POLICY kudos_delete_self ON public.kudos
  FOR DELETE TO authenticated USING (sender_id = auth.uid());

-- ---- kudo_recipients ------------------------------------------------------
-- (0022) anonymity-aware SELECT
CREATE POLICY kudo_recipients_select ON public.kudo_recipients
  FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.kudos k
      WHERE k.id = kudo_recipients.kudo_id
        AND (
          k.is_anonymous = false
          OR k.sender_id     = auth.uid()
          OR kudo_recipients.recipient_id = auth.uid()
        )
    )
  );
CREATE POLICY kudo_recipients_insert ON public.kudo_recipients
  FOR INSERT TO authenticated WITH CHECK (
    EXISTS (SELECT 1 FROM public.kudos WHERE id = kudo_id AND sender_id = auth.uid())
  );

-- ---- kudo_hashtags --------------------------------------------------------
CREATE POLICY kudo_hashtags_select ON public.kudo_hashtags
  FOR SELECT TO authenticated USING (true);
CREATE POLICY kudo_hashtags_insert ON public.kudo_hashtags
  FOR INSERT TO authenticated WITH CHECK (
    EXISTS (SELECT 1 FROM public.kudos WHERE id = kudo_id AND sender_id = auth.uid())
  );

-- ---- kudo_hearts ----------------------------------------------------------
CREATE POLICY kudo_hearts_select ON public.kudo_hearts
  FOR SELECT TO authenticated USING (true);
CREATE POLICY kudo_hearts_insert_self ON public.kudo_hearts
  FOR INSERT TO authenticated WITH CHECK (user_id = auth.uid());
CREATE POLICY kudo_hearts_delete_self ON public.kudo_hearts
  FOR DELETE TO authenticated USING (user_id = auth.uid());

-- ---- kudo_images ----------------------------------------------------------
CREATE POLICY kudo_images_select_authenticated ON public.kudo_images
  FOR SELECT TO authenticated USING (true);
CREATE POLICY kudo_images_insert_sender ON public.kudo_images
  FOR INSERT TO authenticated WITH CHECK (
    EXISTS (SELECT 1 FROM public.kudos WHERE id = kudo_id AND sender_id = auth.uid())
  );
CREATE POLICY kudo_images_delete_sender ON public.kudo_images
  FOR DELETE TO authenticated USING (
    EXISTS (SELECT 1 FROM public.kudos WHERE id = kudo_id AND sender_id = auth.uid())
  );

-- ---- kudo_moderation_events (0022) ----------------------------------------
CREATE POLICY kudo_moderation_events_select_author ON public.kudo_moderation_events
  FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.kudos k
      WHERE k.id = kudo_moderation_events.kudo_id
        AND k.sender_id = auth.uid()
    )
  );
-- Writes: service_role only.

-- ---- kudo_reports (0028) --------------------------------------------------
CREATE POLICY kudo_reports_select_self ON public.kudo_reports
  FOR SELECT TO authenticated USING (reporter_id = auth.uid());
CREATE POLICY kudo_reports_insert_non_self ON public.kudo_reports
  FOR INSERT TO authenticated WITH CHECK (
    reporter_id = auth.uid()
    AND NOT EXISTS (
      SELECT 1 FROM public.kudos k
      WHERE k.id = kudo_reports.kudo_id
        AND k.sender_id = auth.uid()
    )
  );

-- ---- notifications (0024) -------------------------------------------------
CREATE POLICY notifications_select_self ON public.notifications
  FOR SELECT TO authenticated USING (recipient_id = auth.uid());
CREATE POLICY notifications_mark_read ON public.notifications
  FOR UPDATE TO authenticated
  USING      (recipient_id = auth.uid())
  WITH CHECK (recipient_id = auth.uid());
-- INSERT: trigger-based (SECURITY DEFINER) only.

-- ---- awards (0025) --------------------------------------------------------
CREATE POLICY awards_select_authenticated ON public.awards
  FOR SELECT TO authenticated USING (true);
-- Writes: service_role only (admin catalogue curation).

-- ---- gift_redemptions -----------------------------------------------------
CREATE POLICY gift_redemptions_select_authenticated ON public.gift_redemptions
  FOR SELECT TO authenticated USING (true);
-- Writes: service_role only.

-- ---- secret_boxes ---------------------------------------------------------
-- (0023) UPDATE policy removed; opening via open_secret_box() RPC only.
CREATE POLICY secret_boxes_select_self ON public.secret_boxes
  FOR SELECT TO authenticated USING (user_id = auth.uid());

-- ============================================================================
-- REALTIME PUBLICATION (0024)
-- ============================================================================
-- Tables available on the supabase_realtime publication for the iOS clients:
--   • public.notifications — bell dot + inbox prepend
--   • public.kudos          — Sun*Kudos live ticker + All Kudos prepend
--   • public.kudo_hearts    — Sun*Kudos heart animation
-- (Publication membership is idempotent; see 0024 for the guarded ALTER.)

-- ============================================================================
-- STORAGE
-- ============================================================================
-- Bucket `kudo-images` is private; reads use signed URLs at render time.
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'kudo-images',
  'kudo-images',
  false,
  5242880,                                           -- 5 MB
  ARRAY['image/jpeg', 'image/png', 'image/webp']
)
ON CONFLICT (id) DO NOTHING;

CREATE POLICY kudo_images_read_authenticated ON storage.objects
  FOR SELECT TO authenticated
  USING (bucket_id = 'kudo-images');
CREATE POLICY kudo_images_insert_own ON storage.objects
  FOR INSERT TO authenticated
  WITH CHECK (bucket_id = 'kudo-images' AND owner = auth.uid());
CREATE POLICY kudo_images_delete_own ON storage.objects
  FOR DELETE TO authenticated
  USING (bucket_id = 'kudo-images' AND owner = auth.uid());

-- iOS clients should convert HEIC → JPEG before upload (easier than adding
-- HEIC to allowed_mime_types given browser rendering implications).

-- ============================================================================
-- SEED DATA — see supabase/seed.sql + migration 0010 (hashtags), 0011
-- (departments), 0025 (awards). Not duplicated here.
-- ============================================================================
