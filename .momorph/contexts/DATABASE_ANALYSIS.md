# Database Analysis — Sun\* Annual Awards 2025 (iOS-compatibility pass)

This document ties the 16 iOS screen specs in [screen_specs/](screen_specs/)
to the database schema at [database-schema.sql](database-schema.sql) and the
7 new migrations in [migrations/](migrations/) (0022–0028) that were added to
close the gaps surfaced in [DATABASE_REVIEW.md](DATABASE_REVIEW.md).

---

## Per-screen data sourcing

| Screen | Primary reads (via Supabase) | Primary writes | Notes |
|--------|------------------------------|----------------|-------|
| [login.md](screen_specs/login.md) | `supabase.auth.getSession()` | `supabase.auth.signInWithOAuth(.google)` | Email-domain allowlist is a client-side navigation gate (not a DB table). |
| [home.md](screen_specs/home.md) | `kudos_with_stats` (top 1 highlight), `awards` (teaser, via 0025), `notifications` count | — | Countdown / event info bundled in app. |
| [access-denied.md](screen_specs/access-denied.md) | — | `supabase.auth.signOut()` | No DB interaction beyond sign-out. |
| [not-found.md](screen_specs/not-found.md) | — | — | Terminal state, zero DB. |
| [notifications.md](screen_specs/notifications.md) | `notifications` (0024) + Realtime subscription | `UPDATE notifications.read_at` (policy-guarded) | 7 typed rows → `notification_type` enum. |
| [profile-me.md](screen_specs/profile-me.md) | `profiles` + `badges` derived from `secret_boxes` (0023 prize columns) + `kudos_with_stats` + stats aggregation | `supabase.rpc("toggle_heart")` (existing pattern) | Stats derived from joins, not a stored aggregate. |
| [profile-other.md](screen_specs/profile-other.md) | Same as Profile bản thân minus stats dashboard + restricted to `recipient_id = :userId` | — | Privacy boundary enforced by `kudo_recipients_select` (0022 anonymity-aware). |
| [the-le.md](screen_specs/the-le.md) | Bundled in app (Option A) | — | Could be served from a `rules` table later. |
| [community-standards.md](screen_specs/community-standards.md) | Bundled in app (Option A) | — | Drives `KudosSpamCriterion` enum used by `kudo_reports.reason_slug` (0028). |
| [award-detail.md](screen_specs/award-detail.md) | `awards` catalogue (0025) | — | Serves all 6 award kinds via `award_kind` enum. |
| [sun-kudos.md](screen_specs/sun-kudos.md) | `kudos_with_stats` filtered by hashtag/department; `hashtags` + `departments`; `kudo_hearts` Realtime (for live ticker); `profile_stats` aggregate | `supabase.rpc("toggle_heart")` | Spotlight Board aggregation is a server-side concern — potentially a dedicated view or Edge Function (TBD). |
| [gui-loi-chuc-kudos.md](screen_specs/gui-loi-chuc-kudos.md) | `profiles` ILIKE search (trigram-indexed in 0027); `hashtags` | `supabase.rpc("create_kudo")` (existing) + Storage upload to `kudo-images` | Client must enforce body ≥ 30 chars AND DB will double-check (0026 NOT VALID CHECK). |
| [all-kudos.md](screen_specs/all-kudos.md) | `kudos_with_stats` (paginated, keyset on `created_at`) | `toggle_heart` | Simple list; reuses everything. |
| [search-sunner.md](screen_specs/search-sunner.md) | `profiles` ILIKE search (trigram-indexed in 0027) | — | Recent searches stored client-side (UserDefaults). |
| [view-kudo.md](screen_specs/view-kudo.md) | `kudos_with_stats` by id (anonymity-redacted); `kudo_hashtags`+`hashtags`; `kudo_images`; `kudo_reports` for owner-authored | `toggle_heart`; `DELETE ON kudos` (0028, owner only); `INSERT INTO kudo_reports` (0028, non-owner) | All reads go through `kudos_feed` to honour anonymity. |
| [open-secret-box.md](screen_specs/open-secret-box.md) | `secret_boxes` count where `opened_at IS NULL` (RLS self-only) | `supabase.rpc("open_secret_box")` (0023 — server-authoritative) | Prize type + badge_kind stored on the opened row. |

---

## Entity → screen cross-reference

| Entity | Screens that read it | Screens that write it (directly or via RPC) |
|--------|---------------------|-----------------------------------|
| `profiles` | All authenticated screens (for header, avatars, names, levels) | Auth trigger auto-inserts on sign-up; honour tier synced by trigger |
| `kudos` (via `kudos_feed`) | Home, Sun*Kudos, All Kudos, Profile bản thân, Profile người khác, View kudo, Notifications (joined) | `create_kudo` RPC writes (all kudo composition goes through this one path) |
| `kudo_hashtags` | Any screen rendering a KudoCard | `create_kudo` |
| `kudo_hearts` | Sun*Kudos, View kudo, All Kudos, Profile feeds | `toggle_heart` (user INSERT/DELETE) — also triggers §3 and §4 |
| `kudo_images` | View kudo, Sun*Kudos, Profile feeds (thumbnails) | `create_kudo` + Storage bucket |
| `kudo_moderation_events` | View kudo (author can see their own moderation history) | Backend / service_role |
| `kudo_reports` | View kudo (reporter sees their own); admin tools | View kudo (non-owner) |
| `notifications` | Notifications inbox, Home bell dot | Writer triggers only |
| `awards` | Home teaser, Award detail | Service_role only |
| `secret_boxes` | Open secret box, Profile bản thân (stats + count) | `open_secret_box` RPC + `maybe_grant_secret_box` trigger |
| `gift_redemptions` | Home leaderboards, Profile (once collected) | Backend / service_role |
| `hashtags` | Gửi lời chúc picker, Sun*Kudos filter | Service_role only (0027) |
| `departments` | Profile cards, Sun*Kudos filter | Service_role only |

---

## Migrations added to support iOS (0022–0028)

All 7 migration files are in [migrations/](migrations/) and are ordered to
be applied sequentially. Each has a header documenting the `DATABASE_REVIEW`
findings it addresses.

| File | Addresses | What it does |
|------|-----------|--------------|
| [0022_anonymity_and_moderation.sql](migrations/0022_anonymity_and_moderation.sql) | §1, §2, §3 | `kudo_status` enum + `status` column; `kudos_feed` view (anonymity-redacted + status-filtered); revoke SELECT on `kudos`; tighten `kudo_recipients` SELECT; `kudo_moderation_events` table. |
| [0023_secret_box_prize_and_rpc.sql](migrations/0023_secret_box_prize_and_rpc.sql) | §4, §5 | `badge_kind` enum; prize columns + CHECK on `secret_boxes`; drop UPDATE policy; `open_secret_box()` RPC; `maybe_grant_secret_box()` trigger. |
| [0024_notifications.sql](migrations/0024_notifications.sql) | §6 | `notification_type` enum; `notifications` table; 6 writer triggers (N1–N6); Realtime publication. |
| [0025_awards_catalogue.sql](migrations/0025_awards_catalogue.sql) | §8 | `award_kind` enum; `awards` table; seeded with 6 rows (MVP/Top Project/Top Talent copy from Figma; other 3 placeholder). |
| [0026_length_constraints_and_hashtag_cap.sql](migrations/0026_length_constraints_and_hashtag_cap.sql) | §10, §11, §13 | `kudos_body_length` + `kudos_title_length` CHECKs (NOT VALID); `enforce_kudo_hashtag_limit()` trigger. |
| [0027_search_trigram_and_hashtag_lock.sql](migrations/0027_search_trigram_and_hashtag_lock.sql) | §9, §22 | `pg_trgm` extension + GIN index on `display_name`; drop `hashtags_insert_authenticated` policy. |
| [0028_kudo_delete_and_reports.sql](migrations/0028_kudo_delete_and_reports.sql) | §16, view-kudo.md action matrix | Author-DELETE on `kudos`; `kudo_reports` table (UNIQUE reporter+kudo). |

### Legacy data to verify BEFORE validating constraints

Migration 0026 adds CHECKs as `NOT VALID`. Before running
`ALTER TABLE ... VALIDATE CONSTRAINT`, run these audit queries:

```sql
-- Bodies outside 30..2000 chars:
SELECT COUNT(*) FROM public.kudos
WHERE char_length(btrim(body)) < 30
   OR char_length(btrim(body)) > 2000;

-- Titles outside 3..80 chars (note: "Lời cám ơn" backfill is 10 chars — OK):
SELECT COUNT(*) FROM public.kudos
WHERE title IS NOT NULL
  AND char_length(btrim(title)) NOT BETWEEN 3 AND 80;

-- Kudos with > 5 hashtags (expected 0 if create_kudo is the only writer):
SELECT kudo_id, COUNT(*)
FROM public.kudo_hashtags
GROUP BY kudo_id
HAVING COUNT(*) > 5;
```

Fix any offending rows, then VALIDATE.

---

## Client integration checklist

Update the iOS Data layer + repository implementations to:

- [ ] Read **`kudos_feed`** (or `kudos_with_stats`) instead of `kudos`.
- [ ] Call **`open_secret_box()` RPC** instead of client-UPDATE for box reveals.
- [ ] Subscribe to **Realtime publication** on `notifications`, `kudos`,
      `kudo_hearts` (already enabled by 0024).
- [ ] Use the **`awards`** table (or keep Option A bundled content —
      product call; both work).
- [ ] Convert HEIC photos to JPEG client-side before upload to
      `kudo-images`.
- [ ] Remove any UI affordance for "create new hashtag" in the Gửi lời
      chúc picker — hashtags are admin-curated.
- [ ] For the View-kudo action-buttons: show Share + Report for non-
      owners, Share + Delete for owners; wire to `DELETE ON kudos` and
      `INSERT INTO kudo_reports`.
- [ ] Local client validation mirrors the DB:
      - body ≥ 30 chars / ≤ 2000 chars,
      - title 3..80 chars,
      - at most 5 hashtags,
      - at most 5 images.

Corresponding spec updates (cosmetic):

- [ ] Update [gui-loi-chuc-kudos.md](screen_specs/gui-loi-chuc-kudos.md)
      §Security section to reference bucket name `kudo-images` (was
      `kudo_attachments`).
- [ ] Update [home.md](screen_specs/home.md) API mapping to call
      `awards` table (or confirm Option A).
- [ ] Confirm [view-kudo.md](screen_specs/view-kudo.md) action matrix
      matches Owner→Delete+Share / Viewer→Share+Report (the
      product-TBC clause can be closed now).

---

## Outputs

```
.momorph/contexts/
├── DATABASE_ANALYSIS.md    ← this file
├── DATABASE_DESIGN.md      ← ERD (updated)
├── DATABASE_REVIEW.md      ← findings log (§1..§23)
├── database-schema.sql     ← target-state snapshot (post-0028)
└── migrations/
    ├── 0022_anonymity_and_moderation.sql
    ├── 0023_secret_box_prize_and_rpc.sql
    ├── 0024_notifications.sql
    ├── 0025_awards_catalogue.sql
    ├── 0026_length_constraints_and_hashtag_cap.sql
    ├── 0027_search_trigram_and_hashtag_lock.sql
    └── 0028_kudo_delete_and_reports.sql
```

---

## Recommended roll-out order

1. **Dev/staging first**. Apply 0022–0028 in order. Run the audit queries
   in §0026 against real data BEFORE validating constraints.
2. **Smoke tests** per migration:
   - 0022: anonymous sender identity is not fetchable via `SELECT *` as a
     non-author; `kudos_feed` returns redacted rows; soft-hidden kudos
     invisible to non-authors.
   - 0023: RPC call rejects unauthenticated; assigns a badge; concurrent
     calls don't double-open the same box.
   - 0024: compose a kudo → recipient gets N1; heart a kudo → sender
     gets N2; etc.
   - 0025: `SELECT * FROM awards WHERE kind = 'mvp'` returns the seeded
     row.
   - 0026: inserting a too-short body raises; inserting a 6th hashtag
     raises.
   - 0027: `EXPLAIN ANALYZE` on `WHERE display_name ILIKE '%An%'` uses
     the GIN index.
   - 0028: author can DELETE own kudo; non-author can INSERT one
     `kudo_reports` row per kudo.
3. **Client cutover**: iOS (+ web if applicable) updates to read
   `kudos_feed` and call `open_secret_box()`.
4. **Validate** the NOT VALID constraints once legacy data is clean.
5. **Production rollout** with the same sequence.
