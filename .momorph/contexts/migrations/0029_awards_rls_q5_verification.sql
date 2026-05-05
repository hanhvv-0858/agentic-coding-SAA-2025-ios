-- ============================================================================
-- Migration 0029 — awards RLS Q5 verification (idempotent no-op on staging)
-- ============================================================================
-- Spec [.momorph/specs/OuH1BUTYT0-home/spec.md] Q5 resolution (2026-04-27):
--   public.awards SELECT must require an authenticated session — anon-key
--   clients receive 403/empty.
--
-- Migration 0025 (`awards_catalogue.sql`) already creates the equivalent
-- policy:
--
--   ALTER TABLE public.awards ENABLE ROW LEVEL SECURITY;
--   CREATE POLICY awards_select_authenticated ON public.awards
--     FOR SELECT TO authenticated USING (true);
--
-- This migration is a verification step: it asserts the expected state
-- and is safe to re-apply. If 0025 has not been run yet, the assertion
-- fails loudly so the operator runs 0025 first.
--
-- The integration test `AwardsRLSPolicyTests` runs the equivalent check
-- from the iOS test target.
-- ============================================================================

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'awards'
      AND policyname = 'awards_select_authenticated'
  ) THEN
    RAISE EXCEPTION
      'Q5 RLS policy missing: run migration 0025_awards_catalogue first.';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = 'public'
      AND c.relname = 'awards'
      AND c.relrowsecurity = true
  ) THEN
    RAISE EXCEPTION
      'Q5 RLS not enabled on public.awards: run migration 0025 first.';
  END IF;
END $$;
