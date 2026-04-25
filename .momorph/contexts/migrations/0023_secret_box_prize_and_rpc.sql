-- ============================================================================
-- Migration 0023 — Secret Box prize columns + server-authoritative open RPC
-- ============================================================================
-- Addresses DATABASE_REVIEW findings §4 and §5.
--
-- Problems fixed:
--   • secret_boxes.UPDATE RLS let any client mark any of their own boxes as
--     opened without receiving a prize (and there was no prize column at all).
--   • No server-authoritative `open_secret_box` RPC.
--   • No pipeline that mints a new box when a sender accumulates 5 hearts.
--
-- Strategy:
--   1. Add `badge_kind` enum (canonical 6 SAA icons).
--   2. Extend `secret_boxes` with prize_type / badge_kind / prize_name /
--      prize_asset_key + pairing CHECK.
--   3. Revoke direct UPDATE; provide `open_secret_box()` RPC (SECURITY DEFINER,
--      `FOR UPDATE SKIP LOCKED` lock, server-side prize assignment).
--   4. Trigger `maybe_grant_secret_box()` on kudo_hearts INSERT to mint a new
--      box every time the sender crosses a multiple of 5 total hearts.
--
-- Design choice: the current RPC picks a random badge from the 6-set. Product
-- may want a weighted pool or a "no duplicates until full set collected"
-- policy — swap the assignment block in `open_secret_box` without changing
-- the contract.
-- ============================================================================

BEGIN;

-- ----------------------------------------------------------------------------
-- 1. Badge kind enum
-- ----------------------------------------------------------------------------

CREATE TYPE public.badge_kind AS ENUM (
  'revival',
  'touch_of_light',
  'stay_gold',
  'flow_to_horizon',
  'beyond_the_boundary',
  'root_further'
);

-- ----------------------------------------------------------------------------
-- 2. Extend secret_boxes with prize fields
-- ----------------------------------------------------------------------------

ALTER TABLE public.secret_boxes
  ADD COLUMN prize_type        text,
  ADD COLUMN badge_kind        public.badge_kind,
  ADD COLUMN prize_name        text,
  ADD COLUMN prize_asset_key   text;

ALTER TABLE public.secret_boxes
  ADD CONSTRAINT secret_boxes_prize_type_domain
    CHECK (prize_type IS NULL OR prize_type IN ('badge', 'physical'));

-- Pairing invariant: opened_at ↔ prize_type present together.
ALTER TABLE public.secret_boxes
  ADD CONSTRAINT secret_boxes_prize_pairing CHECK (
    (opened_at IS NULL     AND prize_type IS NULL AND badge_kind IS NULL
                           AND prize_name IS NULL AND prize_asset_key IS NULL)
    OR
    (opened_at IS NOT NULL AND prize_type IS NOT NULL)
  );

-- When prize_type = 'badge', badge_kind must be set; when 'physical',
-- prize_name must be set.
ALTER TABLE public.secret_boxes
  ADD CONSTRAINT secret_boxes_prize_shape CHECK (
    (prize_type IS NULL)
    OR (prize_type = 'badge'    AND badge_kind IS NOT NULL)
    OR (prize_type = 'physical' AND prize_name IS NOT NULL AND length(btrim(prize_name)) > 0)
  );

-- ----------------------------------------------------------------------------
-- 3. Revoke direct UPDATE — opening must go through the RPC
-- ----------------------------------------------------------------------------

DROP POLICY IF EXISTS secret_boxes_open_self ON public.secret_boxes;

-- The existing SELECT policy (secret_boxes_select_self) is retained.
-- Direct UPDATE by `authenticated` is no longer possible; service_role retains.

-- ----------------------------------------------------------------------------
-- 4. open_secret_box() — server-authoritative reveal
--
-- Returns the updated row. Uses `FOR UPDATE SKIP LOCKED` so concurrent calls
-- don't double-open the same box. Atomicity: single transaction.
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
    'revival',
    'touch_of_light',
    'stay_gold',
    'flow_to_horizon',
    'beyond_the_boundary',
    'root_further'
  ]::public.badge_kind[];
  chosen_kind public.badge_kind;
BEGIN
  IF uid IS NULL THEN
    RAISE EXCEPTION 'open_secret_box: not authenticated';
  END IF;

  -- Concurrency-safe pick: lock the oldest unopened box for this user
  SELECT * INTO box
  FROM public.secret_boxes
  WHERE user_id = uid AND opened_at IS NULL
  ORDER BY created_at ASC
  FOR UPDATE SKIP LOCKED
  LIMIT 1;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'open_secret_box: no_unopened_box_for_user';
  END IF;

  -- v1 prize policy: uniform random over the 6 badges.
  -- (Replace this block with a weighted or "fill-missing" policy as product refines.)
  chosen_kind := pool[1 + floor(random() * array_length(pool, 1))::int];

  UPDATE public.secret_boxes
  SET opened_at        = now(),
      prize_type       = 'badge',
      badge_kind       = chosen_kind,
      prize_name       = NULL,
      prize_asset_key  = 'badge_' || chosen_kind::text
  WHERE id = box.id
  RETURNING * INTO box;

  RETURN box;
END;
$$;

REVOKE ALL    ON FUNCTION public.open_secret_box() FROM public;
GRANT  EXECUTE ON FUNCTION public.open_secret_box() TO authenticated;

-- ----------------------------------------------------------------------------
-- 5. maybe_grant_secret_box() — trigger on kudo_hearts INSERT
--
-- Business rule (Thể lệ): every 5 hearts received on your sent kudos → 1 box.
-- Implementation: count current total hearts on sender's kudos, count existing
-- boxes, insert a new box whenever `hearts / 5 > boxes`. This is idempotent-
-- ish (never over-grants under single-threaded execution); under concurrency,
-- we serialize per-sender via an advisory lock.
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
  SELECT k.sender_id INTO sender
  FROM public.kudos k
  WHERE k.id = NEW.kudo_id;

  IF sender IS NULL THEN
    RETURN NEW;
  END IF;

  -- Serialize concurrent heart inserts for this sender
  lock_key := hashtextextended(sender::text, 42);
  PERFORM pg_advisory_xact_lock(lock_key);

  SELECT COUNT(*) INTO total_hearts
  FROM public.kudo_hearts h
  JOIN public.kudos       k ON k.id = h.kudo_id
  WHERE k.sender_id = sender;

  SELECT COUNT(*) INTO total_boxes
  FROM public.secret_boxes
  WHERE user_id = sender;

  IF (total_hearts / 5) > total_boxes THEN
    INSERT INTO public.secret_boxes (user_id) VALUES (sender);
  END IF;

  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_grant_secret_box_on_heart
  AFTER INSERT ON public.kudo_hearts
  FOR EACH ROW
  EXECUTE FUNCTION public.maybe_grant_secret_box();

COMMIT;
