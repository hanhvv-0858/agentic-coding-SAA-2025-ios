-- ============================================================================
-- Migration 0027 — Trigram index for search + hashtag INSERT cleanup
-- ============================================================================
-- Addresses DATABASE_REVIEW findings §9 and §22.
--
-- Problems fixed:
--   • `ilike('%q%')` on `profiles.display_name` (used by Search Sunner and
--     the RecipientPickerSheet in Gửi lời chúc) falls back to sequential
--     scans. At Sun* scale this gets painful per keystroke.
--   • `hashtags_insert_authenticated WITH CHECK (true)` lets any
--     authenticated user create arbitrary hashtag rows — which conflicts
--     with the "13 canonical Sun* Q4 2025 hashtags" curation intent.
-- ============================================================================

BEGIN;

-- ----------------------------------------------------------------------------
-- 1. Trigram search index on profiles.display_name
-- ----------------------------------------------------------------------------

CREATE EXTENSION IF NOT EXISTS pg_trgm;

CREATE INDEX profiles_display_name_trgm
  ON public.profiles
  USING gin (display_name gin_trgm_ops);

-- ----------------------------------------------------------------------------
-- 2. Lock hashtags down to admin-only writes
-- ----------------------------------------------------------------------------

DROP POLICY IF EXISTS hashtags_insert_authenticated ON public.hashtags;

-- No INSERT policy for `authenticated` = only service_role can write.
-- If the team wants authenticated users to propose new hashtags in the
-- future, replace with a policy that also writes to a moderation queue.

COMMIT;
