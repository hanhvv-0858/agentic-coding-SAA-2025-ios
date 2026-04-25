-- ============================================================================
-- Migration 0024 — Notifications inbox + writer triggers
-- ============================================================================
-- Addresses DATABASE_REVIEW finding §6.
--
-- Problems fixed:
--   • The notifications inbox, bell dot, and N1–N7 typed rows are required by
--     [screen_specs/notifications.md] but no `notifications` table exists.
--
-- Strategy:
--   1. `notification_type` enum covering all 7 row variants.
--   2. `notifications` table with recipient_id + type + JSONB payload.
--   3. RLS: recipient can SELECT own; can UPDATE to set `read_at`.
--   4. Writer triggers:
--        • kudo_recipients INSERT → N1 kudos_received
--        • kudo_hearts INSERT (liker ≠ kudo.sender) → N2 kudos_liked
--        • secret_boxes INSERT → N3 secret_box_granted
--        • profiles.honour_title change → N4 level_up
--        • kudos.status change to soft_hidden → N5 content_soft_hidden
--        • gift_redemptions INSERT → N6 badge_collected
--   5. N7 admin_review_request is reserved; backend writes as needed.
--   6. Realtime publication added for live prepend on the inbox screen.
-- ============================================================================

BEGIN;

-- ----------------------------------------------------------------------------
-- 1. Notification type enum
-- ----------------------------------------------------------------------------

CREATE TYPE public.notification_type AS ENUM (
  'kudos_received',
  'kudos_liked',
  'secret_box_granted',
  'level_up',
  'content_soft_hidden',
  'badge_collected',
  'admin_review_request'
);

-- ----------------------------------------------------------------------------
-- 2. notifications table
-- ----------------------------------------------------------------------------

CREATE TABLE public.notifications (
  id            uuid                     PRIMARY KEY DEFAULT gen_random_uuid(),
  recipient_id  uuid                     NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  type          public.notification_type NOT NULL,
  payload       jsonb                    NOT NULL DEFAULT '{}'::jsonb,
  read_at       timestamptz,
  created_at    timestamptz              NOT NULL DEFAULT now()
);

-- Primary feed query: `WHERE recipient_id = :uid ORDER BY created_at DESC`
CREATE INDEX notifications_recipient_created
  ON public.notifications (recipient_id, created_at DESC);

-- Unread-count query: `WHERE recipient_id = :uid AND read_at IS NULL`
CREATE INDEX notifications_unread_partial
  ON public.notifications (recipient_id)
  WHERE read_at IS NULL;

-- ----------------------------------------------------------------------------
-- 3. RLS
-- ----------------------------------------------------------------------------

ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

-- Recipient can read their own notifications
CREATE POLICY notifications_select_self ON public.notifications
  FOR SELECT TO authenticated
  USING (recipient_id = auth.uid());

-- Recipient can mark their own notifications as read (UPDATE read_at).
-- The WITH CHECK guards that the row is still theirs after update.
CREATE POLICY notifications_mark_read ON public.notifications
  FOR UPDATE TO authenticated
  USING      (recipient_id = auth.uid())
  WITH CHECK (recipient_id = auth.uid());

-- INSERT is backend-only — no authenticated policy. Writer triggers below
-- run as SECURITY DEFINER and therefore bypass RLS.

-- ----------------------------------------------------------------------------
-- 4. Writer triggers
-- ----------------------------------------------------------------------------

-- N1 kudos_received — fire when kudo_recipients inserts a row (i.e. a kudo has
-- been composed and delivered). One notification per recipient per kudo.
-- We skip N1 if the recipient is also the sender (self-kudos — unusual but
-- possible).
CREATE OR REPLACE FUNCTION public.notify_kudos_received()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  k_sender uuid;
BEGIN
  SELECT sender_id INTO k_sender FROM public.kudos WHERE id = NEW.kudo_id;
  IF k_sender IS NULL OR k_sender = NEW.recipient_id THEN
    RETURN NEW;
  END IF;

  INSERT INTO public.notifications (recipient_id, type, payload)
  VALUES (
    NEW.recipient_id,
    'kudos_received',
    jsonb_build_object('kudo_id', NEW.kudo_id)
  );
  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_notify_kudos_received
  AFTER INSERT ON public.kudo_recipients
  FOR EACH ROW
  EXECUTE FUNCTION public.notify_kudos_received();

-- N2 kudos_liked — fire when a user hearts a kudo whose sender isn't them.
-- Sender receives the notification.
CREATE OR REPLACE FUNCTION public.notify_kudos_liked()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  k_sender uuid;
BEGIN
  SELECT sender_id INTO k_sender FROM public.kudos WHERE id = NEW.kudo_id;
  IF k_sender IS NULL OR k_sender = NEW.user_id THEN
    RETURN NEW;
  END IF;

  INSERT INTO public.notifications (recipient_id, type, payload)
  VALUES (
    k_sender,
    'kudos_liked',
    jsonb_build_object(
      'kudo_id', NEW.kudo_id,
      'liker_id', NEW.user_id
    )
  );
  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_notify_kudos_liked
  AFTER INSERT ON public.kudo_hearts
  FOR EACH ROW
  EXECUTE FUNCTION public.notify_kudos_liked();

-- N3 secret_box_granted — fire when a new unopened box is inserted.
-- Skip service_role bulk backfills by scoping via a sentinel (not included
-- here; bulk ops can disable the trigger temporarily).
CREATE OR REPLACE FUNCTION public.notify_secret_box_granted()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NEW.opened_at IS NOT NULL THEN
    -- Only notify for freshly-minted (unopened) boxes
    RETURN NEW;
  END IF;

  INSERT INTO public.notifications (recipient_id, type, payload)
  VALUES (
    NEW.user_id,
    'secret_box_granted',
    jsonb_build_object('secret_box_id', NEW.id)
  );
  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_notify_secret_box_granted
  AFTER INSERT ON public.secret_boxes
  FOR EACH ROW
  EXECUTE FUNCTION public.notify_secret_box_granted();

-- N4 level_up — fire when profiles.honour_title transitions upward.
-- Thresholds from compute_honour_tier: New(1..4) < Rising(5..9) < Super(10..19) < Legend(≥20).
CREATE OR REPLACE FUNCTION public.notify_level_up()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  old_rank int;
  new_rank int;
  rank_of public.honour_title;
BEGIN
  IF NEW.honour_title IS NULL OR NEW.honour_title = OLD.honour_title THEN
    RETURN NEW;
  END IF;

  -- Map enum to an ordered rank (higher = better)
  old_rank := CASE OLD.honour_title
    WHEN 'New Hero'    THEN 1
    WHEN 'Rising Hero' THEN 2
    WHEN 'Super Hero'  THEN 3
    WHEN 'Legend Hero' THEN 4
    ELSE 0
  END;
  new_rank := CASE NEW.honour_title
    WHEN 'New Hero'    THEN 1
    WHEN 'Rising Hero' THEN 2
    WHEN 'Super Hero'  THEN 3
    WHEN 'Legend Hero' THEN 4
    ELSE 0
  END;

  -- Only fire on upward transitions
  IF new_rank > old_rank THEN
    INSERT INTO public.notifications (recipient_id, type, payload)
    VALUES (
      NEW.id,
      'level_up',
      jsonb_build_object(
        'from_title', OLD.honour_title,
        'to_title',   NEW.honour_title
      )
    );
  END IF;
  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_notify_level_up
  AFTER UPDATE OF honour_title ON public.profiles
  FOR EACH ROW
  EXECUTE FUNCTION public.notify_level_up();

-- N5 content_soft_hidden — fire when kudos.status flips to soft_hidden.
-- Recipient is the kudo's sender (they're the one whose content was hidden).
CREATE OR REPLACE FUNCTION public.notify_content_soft_hidden()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NEW.status = 'soft_hidden' AND OLD.status <> 'soft_hidden' THEN
    INSERT INTO public.notifications (recipient_id, type, payload)
    VALUES (
      NEW.sender_id,
      'content_soft_hidden',
      jsonb_build_object('kudo_id', NEW.id)
    );
  END IF;
  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_notify_content_soft_hidden
  AFTER UPDATE OF status ON public.kudos
  FOR EACH ROW
  EXECUTE FUNCTION public.notify_content_soft_hidden();

-- N6 badge_collected — fire when a gift_redemption is inserted.
-- (N6 semantically covers both "you collected all 6 badges → here's your
-- physical prize" AND any other gift source. Per Thể lệ: UNIQUE on user_id
-- means one prize per Sunner lifetime.)
CREATE OR REPLACE FUNCTION public.notify_badge_collected()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.notifications (recipient_id, type, payload)
  VALUES (
    NEW.user_id,
    'badge_collected',
    jsonb_build_object(
      'gift_redemption_id', NEW.id,
      'gift_name',          NEW.gift_name,
      'quantity',           NEW.quantity,
      'source',             NEW.source
    )
  );
  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_notify_badge_collected
  AFTER INSERT ON public.gift_redemptions
  FOR EACH ROW
  EXECUTE FUNCTION public.notify_badge_collected();

-- N7 admin_review_request is inserted by backend-only logic (not via trigger).

-- ----------------------------------------------------------------------------
-- 5. Realtime publication
-- ----------------------------------------------------------------------------

-- Add notifications to the supabase_realtime publication so the iOS bell
-- (Home header) + Notifications inbox + live ticker on Sun*Kudos can
-- subscribe to INSERTs. We also add kudos and kudo_hearts for the Sun*Kudos
-- live ticker + All Kudos prepend-on-insert behaviour.
DO $$
BEGIN
  BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.notifications;
  EXCEPTION WHEN duplicate_object THEN NULL;
  END;
  BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.kudos;
  EXCEPTION WHEN duplicate_object THEN NULL;
  END;
  BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.kudo_hearts;
  EXCEPTION WHEN duplicate_object THEN NULL;
  END;
END
$$;

COMMIT;
