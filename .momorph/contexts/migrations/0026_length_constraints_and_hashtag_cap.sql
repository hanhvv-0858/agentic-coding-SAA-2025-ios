-- ============================================================================
-- Migration 0026 — Length constraints + hashtag count cap
-- ============================================================================
-- Addresses DATABASE_REVIEW findings §10, §11, §13.
--
-- Problems fixed:
--   • kudos.body has no length bound (spec: 30..2000 chars, driven by
--     community-standards.md criterion #7).
--   • kudos.title has no length bound (spec: 3..80 chars).
--   • kudo_hashtags has no DB-level cap (create_kudo enforces ≤5 but a
--     direct INSERT via RLS could bypass it).
--
-- Strategy:
--   • Add CHECK constraints as NOT VALID so existing legacy data isn't
--     blocked from being read; VALIDATE in a later migration once data is
--     backfilled / cleaned.
--   • Trigger mirroring `enforce_kudo_image_limit` for hashtags.
--
-- IMPORTANT — legacy data:
--   If any existing kudos have `body` shorter than 30 or longer than 2000
--   chars, or `title` outside 3..80 chars, the VALIDATE CONSTRAINT step at
--   the end of this migration will fail. Run the audit queries in the
--   Review section below BEFORE applying.
-- ============================================================================

BEGIN;

-- ----------------------------------------------------------------------------
-- 1. Body length — 30..2000 (added NOT VALID; validate separately if needed)
-- ----------------------------------------------------------------------------

ALTER TABLE public.kudos
  ADD CONSTRAINT kudos_body_length
    CHECK (char_length(btrim(body)) BETWEEN 30 AND 2000)
    NOT VALID;

-- After backfilling / verifying legacy rows, uncomment:
-- ALTER TABLE public.kudos VALIDATE CONSTRAINT kudos_body_length;

-- ----------------------------------------------------------------------------
-- 2. Title length — 3..80
-- ----------------------------------------------------------------------------

ALTER TABLE public.kudos
  ADD CONSTRAINT kudos_title_length
    CHECK (title IS NULL OR char_length(btrim(title)) BETWEEN 3 AND 80)
    NOT VALID;

-- After backfilling / verifying:
-- ALTER TABLE public.kudos VALIDATE CONSTRAINT kudos_title_length;

-- ----------------------------------------------------------------------------
-- 3. Hashtag count cap — enforce ≤5 at DB level (defence in depth)
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

CREATE TRIGGER kudo_hashtags_limit
  BEFORE INSERT ON public.kudo_hashtags
  FOR EACH ROW
  EXECUTE FUNCTION public.enforce_kudo_hashtag_limit();

-- ----------------------------------------------------------------------------
-- 4. Review queries (commented — run by hand before VALIDATE)
-- ----------------------------------------------------------------------------

-- -- Count kudos that would violate the body-length constraint:
-- SELECT COUNT(*)
-- FROM public.kudos
-- WHERE char_length(btrim(body)) < 30
--    OR char_length(btrim(body)) > 2000;
--
-- -- Count kudos that would violate the title-length constraint:
-- SELECT COUNT(*)
-- FROM public.kudos
-- WHERE title IS NOT NULL
--   AND char_length(btrim(title)) NOT BETWEEN 3 AND 80;
--
-- -- Count kudos that currently have more than 5 hashtags (should be 0 if
-- -- create_kudo has always been the only writer; if > 0, clean up first):
-- SELECT kudo_id, COUNT(*)
-- FROM public.kudo_hashtags
-- GROUP BY kudo_id
-- HAVING COUNT(*) > 5;

COMMIT;
