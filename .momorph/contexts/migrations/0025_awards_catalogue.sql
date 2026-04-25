-- ============================================================================
-- Migration 0025 — Awards catalogue
-- ============================================================================
-- Addresses DATABASE_REVIEW finding §8.
--
-- Problems fixed:
--   • [screen_specs/home.md] + [screen_specs/award-detail.md] query an
--     `awards` table that does not exist. iOS can ship Option A (bundled
--     content) but this table gives the web admin a way to edit award copy
--     without shipping app updates, and provides a single source of truth
--     for both clients.
--
-- Strategy:
--   • `award_kind` enum with the 6 canonical SAA 2025 categories.
--   • `awards` table keyed on `kind` (there is exactly one row per kind).
--   • Bilingual title + description fields mirroring the `hashtags` /
--     `departments` pattern.
--   • Seed stub rows with placeholder copy — real content is captured in
--     the corresponding `/momorph.specs` run + copied into this table by
--     the editorial team (or backfilled via a later migration).
-- ============================================================================

BEGIN;

-- ----------------------------------------------------------------------------
-- 1. Award kind enum
-- ----------------------------------------------------------------------------

CREATE TYPE public.award_kind AS ENUM (
  'mvp',
  'best_manager',
  'signature_creator',
  'top_project',
  'top_project_leader',
  'top_talent'
);

-- ----------------------------------------------------------------------------
-- 2. awards table
-- ----------------------------------------------------------------------------

CREATE TABLE public.awards (
  kind              public.award_kind PRIMARY KEY,
  title_vi          text NOT NULL,
  title_en          text NOT NULL,
  description_vi    text NOT NULL,
  description_en    text NOT NULL,
  artwork_asset_key text NOT NULL,                       -- e.g. 'award_mvp'
  display_order     smallint NOT NULL,                   -- sort for Home teaser + Awards tab
  created_at        timestamptz NOT NULL DEFAULT now(),
  updated_at        timestamptz NOT NULL DEFAULT now()
);

CREATE UNIQUE INDEX awards_display_order ON public.awards (display_order);

-- ----------------------------------------------------------------------------
-- 3. RLS
-- ----------------------------------------------------------------------------

ALTER TABLE public.awards ENABLE ROW LEVEL SECURITY;

-- All authenticated users can read the catalogue.
CREATE POLICY awards_select_authenticated ON public.awards
  FOR SELECT TO authenticated USING (true);

-- Writes are admin-only (service_role). No INSERT/UPDATE/DELETE policy for
-- `authenticated`.

-- ----------------------------------------------------------------------------
-- 4. Seed placeholder rows (copy lifted from [award-detail.md] samples)
--
-- The 3 rows with verbatim copy (MVP, top_project, top_talent) come directly
-- from the Figma frames inspected during /momorph.screenflow. The remaining
-- 3 (best_manager, signature_creator, top_project_leader) are placeholders
-- to be replaced during /momorph.specs when the corresponding frames are
-- inspected.
-- ----------------------------------------------------------------------------

INSERT INTO public.awards (kind, title_vi, title_en, description_vi, description_en, artwork_asset_key, display_order)
VALUES
  (
    'mvp',
    'MVP',
    'MVP',
    'Giải thưởng MVP vinh danh cá nhân xuất sắc nhất năm – gương mặt tiêu biểu đại diện cho toàn bộ tập thể Sun*. Họ là người đã thể hiện năng lực vượt trội, tinh thần cống hiến bền bỉ, và tầm ảnh hưởng sâu rộng, để lại dấu ấn mạnh mẽ trong hành trình của Sun* suốt năm qua.',
    'TODO: English copy for MVP',
    'award_mvp',
    1
  ),
  (
    'best_manager',
    'Best Manager',
    'Best Manager',
    'TODO: Vietnamese description for Best Manager',
    'TODO: English description for Best Manager',
    'award_best_manager',
    2
  ),
  (
    'signature_creator',
    'Signature 2025 — Creator',
    'Signature 2025 — Creator',
    'TODO: Vietnamese description for Signature Creator',
    'TODO: English description for Signature Creator',
    'award_signature_creator',
    3
  ),
  (
    'top_project',
    'Top Project',
    'Top Project',
    'Giải thưởng Top Project vinh danh các tập thể dự án xuất sắc với kết quả kinh doanh vượt kỳ vọng, hiệu quả vận hành tối ưu và tinh thần làm việc tận tâm. Đây là các dự án có độ phức tạp kỹ thuật cao, hiệu quả tối ưu hóa nguồn lực và chi phí tốt, đề xuất các ý tưởng có giá trị cho khách hàng, đem lại lợi nhuận vượt trội và nhận được phản hồi tích cực từ khách hàng.',
    'TODO: English copy for Top Project',
    'award_top_project',
    4
  ),
  (
    'top_project_leader',
    'Top Project Leader',
    'Top Project Leader',
    'TODO: Vietnamese description for Top Project Leader',
    'TODO: English description for Top Project Leader',
    'award_top_project_leader',
    5
  ),
  (
    'top_talent',
    'Top Talent',
    'Top Talent',
    'Giải thưởng Top Talent vinh danh những cá nhân xuất sắc toàn diện – những người không ngừng khẳng định năng lực chuyên môn vững vàng, hiệu suất công việc vượt trội, luôn mang lại giá trị vượt kỳ vọng, được đánh giá cao bởi khách hàng và đồng đội.',
    'TODO: English copy for Top Talent',
    'award_top_talent',
    6
  )
ON CONFLICT (kind) DO NOTHING;

COMMIT;
