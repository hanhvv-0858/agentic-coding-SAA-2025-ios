# Backend API Test Cases — Sun\* Annual Awards 2025 (iOS)

Functional test cases for every endpoint the iOS client calls. Source of
truth for endpoint contracts is [api-docs.yaml](api-docs.yaml); the target
database schema is [database-schema.sql](database-schema.sql).

**Conventions**:

- `{selfUid}`, `{otherUid}`, `{deptId}`, `{hashtagId}` — fixture UUIDs.
- `{JWT_SELF}` / `{JWT_OTHER}` — bearer tokens for two fixture Sunners.
- `{JWT_ADMIN}` — service-role key (NOT bundled in iOS — for test harness
  only).
- All tests assume migrations 0001–0028 applied.

---

## Test data fixtures

Before running the suite, seed a test project with:

| Fixture | Value |
|---------|-------|
| `selfUid` | Profile A — department `CEVC3`, domain `@sun-asterisk.com` |
| `otherUid` | Profile B — different department, domain `@sun-asterisk.com` |
| `outsiderUid` | Profile C — email domain `@gmail.com` (for allowlist negative tests) |
| `kudoActive` | A kudo from selfUid → otherUid, status=active, non-anonymous, body ≥ 30 chars |
| `kudoAnon` | A kudo from selfUid → otherUid, status=active, is_anonymous=true, anonymous_alias="Fan cuồng" |
| `kudoSoftHidden` | A kudo from selfUid → otherUid, status=soft_hidden |
| `hashtagDedicated` | `slug='dedicated'` (from 0010 seed) |
| `boxUnopenedA`, `boxUnopenedB` | 2 unopened Secret Boxes for selfUid |
| `awardMVP` | From 0025 seed |

---

## Auth

### POST /auth/v1/authorize?provider=google

#### Description
Initiate Google OAuth flow. The client opens the returned `url` in an
`ASWebAuthenticationSession`.

#### Test Cases

| ID | Category | Scenario | Input | Expected | Status |
|----|----------|----------|-------|----------|--------|
| AUTH_01 | Positive | Valid bootstrap call | `apikey=<anon>`, `provider=google`, `redirect_to=app://auth-callback` | Returns `{ provider: "google", url }`; URL is a Google auth URL | 200 |
| AUTH_02 | Negative | Missing `apikey` | No header | `401 / Invalid API key` | 401 |
| AUTH_03 | Negative | Unsupported provider | `provider=facebook` | `400 / Unsupported provider` | 400 |

### POST /auth/v1/token?grant_type=pkce

#### Test Cases

| ID | Category | Scenario | Input | Expected | Status |
|----|----------|----------|-------|----------|--------|
| AUTH_10 | Positive | Valid PKCE exchange | `{ code, code_verifier }` after a completed Google OAuth | `{ access_token, refresh_token, user }` | 200 |
| AUTH_11 | Negative | Bad code | `code="wrong"` | `invalid_grant` error | 400 |
| AUTH_12 | Negative | Replay | Re-submit a valid code after consumption | `invalid_grant` | 400 |
| AUTH_13 | Positive | Refresh | `grant_type=refresh_token` + valid `refresh_token` | Fresh access token | 200 |

### GET /auth/v1/user

| ID | Category | Scenario | Input | Expected | Status |
|----|----------|----------|-------|----------|--------|
| AUTH_20 | Positive | Valid session | `Authorization: Bearer {JWT_SELF}` | Current user JSON | 200 |
| AUTH_21 | Negative | Expired JWT | Bearer token past `exp` | `JWT expired` | 401 |
| AUTH_22 | Negative | No token | No header | `Missing authentication` | 401 |

### POST /auth/v1/logout

| ID | Category | Scenario | Expected | Status |
|----|----------|----------|----------|--------|
| AUTH_30 | Positive | Valid session | Empty body | 204 |
| AUTH_31 | Negative | No token | `Missing authentication` | 401 |

---

## Profiles

### GET /rest/v1/profiles

#### Test Cases

| ID | Category | Scenario | Query | Expected | Status |
|----|----------|----------|-------|----------|--------|
| PROF_01 | Positive | Search by display name | `?display_name=ilike.%An%&select=id,display_name,department_id` | Matching rows incl. profile with "Dương thuý An" | 200 |
| PROF_02 | Positive | Exclude self | `?display_name=ilike.%An%&id=neq.<selfUid>` | Self absent | 200 |
| PROF_03 | Positive | By id | `?id=eq.<otherUid>` | Exactly 1 row | 200 |
| PROF_04 | Negative | No JWT | — | `401` | 401 |
| PROF_05 | Boundary | Empty ILIKE | `?display_name=ilike.%%` | All rows (paginated) | 200 |
| PROF_06 | Perf | Ensure trigram index is used | `EXPLAIN ANALYZE SELECT ... ILIKE '%An%'` | `Bitmap Index Scan on profiles_display_name_trgm` | — |

---

## Kudos (via kudos_feed / kudos_with_stats)

### GET /rest/v1/kudos_feed

#### Anonymity redaction test matrix

| ID | Category | Scenario | Viewer | Kudo | Expected `sender_id` in response |
|----|----------|----------|--------|------|----------------------------------|
| FEED_01 | Positive | Non-anonymous kudo | selfUid | `kudoActive` (by selfUid) | `selfUid` (real) |
| FEED_02 | Positive | Non-anonymous kudo seen by third party | otherUid | `kudoActive` | `selfUid` (real) |
| FEED_03 | **Critical** | Anonymous kudo seen by **author** | selfUid | `kudoAnon` (by selfUid) | `selfUid` (real — author sees own identity) |
| FEED_04 | **Critical** | Anonymous kudo seen by **recipient** | otherUid | `kudoAnon` | **NULL** (recipient doesn't learn identity) |
| FEED_05 | **Critical** | Anonymous kudo seen by **third party** | outsiderUid | `kudoAnon` | **NULL** |
| FEED_06 | Positive | Soft-hidden kudo — author viewer | selfUid | `kudoSoftHidden` (by self) | Row returned (status=soft_hidden) |
| FEED_07 | **Critical** | Soft-hidden kudo — non-author viewer | otherUid | `kudoSoftHidden` | 0 rows returned |
| FEED_08 | Negative | Attempt direct `/rest/v1/kudos` | selfUid | — | `403` or `42501 RLS` | 403 |

### GET /rest/v1/kudos_with_stats

| ID | Category | Scenario | Expected |
|----|----------|----------|----------|
| STATS_01 | Positive | Any row | Includes `hearts_count` integer ≥ 0 |
| STATS_02 | Positive | Ordering by created_at desc | Returned in desc order |
| STATS_03 | Positive | Range header pagination | `Range: 0-19` → 20 rows (or fewer) |

### DELETE /rest/v1/kudos?id=eq.{id}

| ID | Category | Scenario | JWT | Expected | Status |
|----|----------|----------|-----|----------|--------|
| KUDO_DEL_01 | Positive | Author deletes own | selfUid | Row gone from `kudos` | 204 |
| KUDO_DEL_02 | Negative | Non-author | otherUid | RLS denies | 403 |
| KUDO_DEL_03 | Cascading | Verify cascade | — | `kudo_recipients`, `kudo_hashtags`, `kudo_hearts`, `kudo_images`, `kudo_moderation_events`, `kudo_reports` also deleted | — |

---

## Kudo composition (RPC)

### POST /rest/v1/rpc/create_kudo

#### Happy path

| ID | Category | Scenario | Body | Expected | Status |
|----|----------|----------|------|----------|--------|
| CK_01 | Positive | Minimal valid compose | `{ p_title: "Great work!", p_body: <30+ chars>, p_is_anonymous: false, p_recipient_id: <otherUid>, p_hashtag_slugs: ["dedicated"], p_image_paths: [] }` | Returns new UUID; rows in 4 tables | 200 |
| CK_02 | Positive | With images | `p_image_paths: ["<path1>","<path2>"]` | Images attached with position 0 and 1 | 200 |
| CK_03 | Positive | Anonymous compose | `p_is_anonymous: true, p_anonymous_alias: "Fan cuồng"` | Row with `is_anonymous=true` | 200 |

#### Validation failures (all expect 400 + the quoted RAISE EXCEPTION text)

| ID | Category | Scenario | Body | Error message (partial) |
|----|----------|----------|------|-------------------------|
| CK_10 | Validation | Empty title | `p_title: "   "` | `title is required` |
| CK_11 | Validation | Empty body | `p_body: ""` | `body is required` |
| CK_12 | Validation | Body < 30 chars | `p_body: "Cảm ơn"` | CHECK `kudos_body_length` (after VALIDATE) or custom raise |
| CK_13 | Validation | Title < 3 | `p_title: "Hi"` | CHECK `kudos_title_length` |
| CK_14 | Validation | Title > 80 | `p_title: <81-char string>` | CHECK `kudos_title_length` |
| CK_15 | Validation | 0 hashtags | `p_hashtag_slugs: []` | `at least one hashtag is required` |
| CK_16 | Validation | 6 hashtags | `p_hashtag_slugs: [6 slugs]` | `at most 5 hashtags allowed` |
| CK_17 | Validation | 6 images | `p_image_paths: [6 paths]` | `at most 5 images allowed` |
| CK_18 | Validation | Missing recipient | `p_recipient_id: null` | `recipient_id is required` |
| CK_19 | Validation | Anon without alias | `p_is_anonymous: true, p_anonymous_alias: null` | `anonymous_alias must be 2..40 chars when is_anonymous=true` |
| CK_20 | Validation | Anon with 1-char alias | `p_anonymous_alias: "A"` | same |
| CK_21 | Validation | Alias set when not anon | `p_is_anonymous: false, p_anonymous_alias: "X"` | `anonymous_alias must be null when is_anonymous=false` |

#### Side effects

| ID | Category | Scenario | Expected |
|----|----------|----------|----------|
| CK_30 | Side-effect | Honour tier sync | New kudo from a new distinct sender → recipient's `profiles.honour_title` advances per `compute_honour_tier` |
| CK_31 | Side-effect | Notifications N1 | Recipient receives notification `type='kudos_received'` with `payload.kudo_id` |
| CK_32 | Auth | No JWT | `not authenticated` |

---

## Hearts

### POST /rest/v1/kudo_hearts (like)

| ID | Category | Scenario | Body | Expected | Status |
|----|----------|----------|------|----------|--------|
| HEART_01 | Positive | Like a kudo | `{ kudo_id, user_id: <selfUid> }` with `Prefer: resolution=ignore-duplicates` | Row inserted | 201 |
| HEART_02 | Idempotent | Like twice | Repeat same POST | Row still present (ignored duplicate) | 201 |
| HEART_03 | Negative | Spoof user_id | `user_id: <otherUid>` | RLS denies | 403 |
| HEART_04 | Side-effect | Notifications N2 | Sender (if ≠ liker) receives `type='kudos_liked'` notification with `payload.liker_id` | — |
| HEART_05 | Side-effect | Secret Box mint | 5th heart on one of sender's kudos → 1 new unopened `secret_boxes` row | — |
| HEART_06 | Side-effect | Honour tier on heart | no-op (tier depends on distinct-sender count, not hearts) |
| HEART_07 | Edge | Self-heart | liker == kudo.sender | Allowed; no N2 fired for self |

### DELETE /rest/v1/kudo_hearts?kudo_id=eq.{id}&user_id=eq.{self} (unlike)

| ID | Category | Scenario | Expected | Status |
|----|----------|----------|----------|--------|
| HEART_20 | Positive | Unlike own like | Row deleted | 204 |
| HEART_21 | Negative | Delete someone else's like | RLS denies | 403 |
| HEART_22 | Boundary | Unlike when not liked | 0 rows affected | 204 |

---

## Kudo reports

### POST /rest/v1/kudo_reports

| ID | Category | Scenario | Body | Expected | Status |
|----|----------|----------|------|----------|--------|
| RPT_01 | Positive | Non-owner reports | `{ kudo_id: kudoActive, reporter_id: <otherUid>, reason_slug: "profanity" }` | Row inserted | 201 |
| RPT_02 | Negative | Author reports own | reporter_id = kudo.sender_id | RLS denies | 403 |
| RPT_03 | Negative | Spoof reporter_id | reporter_id ≠ auth.uid() | RLS denies | 403 |
| RPT_04 | Unique | Duplicate report | Second POST same (reporter, kudo) | UNIQUE violation | 409 |
| RPT_05 | Validation | Empty reason | `reason_slug: ""` | CHECK violation | 400 |

---

## Secret Box

### GET /rest/v1/secret_boxes

| ID | Category | Scenario | Query | Expected | Status |
|----|----------|----------|-------|----------|--------|
| SB_01 | Positive | Caller's unopened count | `?opened_at=is.null&select=id&Prefer: count=exact` | `Content-Range: 0-*/N` | 200 |
| SB_02 | Positive | Caller's own boxes | `?user_id=eq.<selfUid>` | Only selfUid rows | 200 |
| SB_03 | Security | List another user's boxes | `?user_id=eq.<otherUid>` | 0 rows (RLS) | 200 |

### POST /rest/v1/rpc/open_secret_box

| ID | Category | Scenario | Expected | Status |
|----|----------|----------|----------|--------|
| OSB_01 | Positive | Caller has ≥ 1 unopened | Returns full `secret_boxes` row with `opened_at=NOW`, `prize_type='badge'`, `badge_kind` set, `prize_asset_key='badge_<kind>'` | 200 |
| OSB_02 | Negative | Caller has 0 unopened | Raises `no_unopened_box_for_user` | 400 |
| OSB_03 | Auth | No JWT | Raises `not authenticated` | 401 |
| OSB_04 | Concurrency | 2 parallel calls | Exactly 2 different boxes opened (via `FOR UPDATE SKIP LOCKED`); no box opened twice | — |
| OSB_05 | Post-condition | Re-fetch `secret_boxes` | New `opened_at` visible via `/rest/v1/secret_boxes` | — |
| OSB_06 | Side-effect | Notifications N3 on grant | verified separately via HEART_05 chain |
| OSB_07 | Exploitation | Direct UPDATE `opened_at` | RLS policy dropped in 0023 — 403/42501 | 403 |

---

## Notifications

### GET /rest/v1/notifications

| ID | Category | Scenario | Query | Expected | Status |
|----|----------|----------|-------|----------|--------|
| NOTI_01 | Positive | First page | `?recipient_id=eq.<selfUid>&order=created_at.desc&Range:0-19` | ≤ 20 rows, sorted | 200 |
| NOTI_02 | Positive | Unread count | `?recipient_id=eq.<selfUid>&read_at=is.null&select=id&Prefer:count=exact,head=true` | `Content-Range: */N` | 200 |
| NOTI_03 | Security | Non-self recipient_id | `?recipient_id=eq.<otherUid>` | 0 rows (RLS) | 200 |
| NOTI_04 | Positive | Filter out N7 | `?type=neq.admin_review_request` | Rows without N7 | 200 |
| NOTI_05 | Realtime | Compose a kudo → subscribe to notifications channel | Receive INSERT event matching N1 | — |

### PATCH /rest/v1/notifications

| ID | Category | Scenario | Query + body | Expected | Status |
|----|----------|----------|--------------|----------|--------|
| NOTI_20 | Positive | Mark one read | `?id=eq.<notifId>` + `{ read_at: "<now>" }` | Row updated | 204 |
| NOTI_21 | Positive | Mark all read | `?recipient_id=eq.<self>&read_at=is.null` + `{ read_at: "<now>" }` | All caller's unread rows flipped | 204 |
| NOTI_22 | Security | Mark someone else's | `?id=eq.<notifFromOther>` | RLS denies (0 rows) | 204 (silent), but no rows affected |
| NOTI_23 | Boundary | Mark-all when none unread | Same as NOTI_21 after NOTI_21 | 0 rows affected | 204 |

---

## Awards

### GET /rest/v1/awards

| ID | Category | Scenario | Query | Expected | Status |
|----|----------|----------|-------|----------|--------|
| AW_01 | Positive | List by display order | `?order=display_order.asc` | 6 rows | 200 |
| AW_02 | Positive | By kind | `?kind=eq.mvp&select=*` | 1 row — MVP | 200 |
| AW_03 | Negative | Unauth | No JWT | 401 | 401 |
| AW_04 | Negative | Client tries INSERT | POST `{...}` | RLS denies (no policy) | 403 |

---

## Hashtags

### GET /rest/v1/hashtags

| ID | Category | Scenario | Expected | Status |
|----|----------|----------|----------|--------|
| HT_01 | Positive | List | 13 canonical rows | 200 |
| HT_02 | Negative | Client tries INSERT | POST with `{ slug: "newtag" }` | RLS denies (policy removed in 0027) | 403 |

---

## Storage (`kudo-images`)

### POST /storage/v1/object/kudo-images/{path}

| ID | Category | Scenario | Expected | Status |
|----|----------|----------|----------|--------|
| ST_01 | Positive | JPEG ≤ 5 MB, path = `{selfUid}/{uuid}.jpg` | Stored; returns `{Key}`-style JSON | 200 |
| ST_02 | Negative | HEIC upload | Rejected by MIME allow-list | 400 |
| ST_03 | Negative | File > 5 MB | Rejected by bucket limit | 413 |
| ST_04 | Negative | Upload to someone else's folder | Policy `owner = auth.uid()` denies | 403 |
| ST_05 | Positive | Sign URL | POST `/storage/v1/object/sign/kudo-images/{path}` → signed URL works | 200 |
| ST_06 | Security | Signed URL expiry | Set `expiresIn=1`, wait 2 s → fetch fails | 403 |

---

## Realtime

| ID | Category | Scenario | Expected |
|----|----------|----------|----------|
| RT_01 | Positive | Subscribe to `realtime:public:notifications:recipient_id=eq.<self>` | Receive INSERT when another user composes a kudo for self |
| RT_02 | Positive | Subscribe to `realtime:public:kudos` | Receive INSERT when anyone composes a new kudo (regardless of anonymity, but filter out soft_hidden on client or via server filter) |
| RT_03 | Positive | Subscribe to `realtime:public:kudo_hearts` | Receive INSERT when anyone hearts a kudo |
| RT_04 | Security | Subscribe with expired JWT | Connection rejected |
| RT_05 | Security | Subscribe to `realtime:public:notifications:recipient_id=eq.<other>` | No events received (server filters to self) |

---

## Integration scenarios

### INT-1 — Full compose → view → like → secret-box flow

1. **Self composes a kudo to Other**
   - POST `/rest/v1/rpc/create_kudo` → 200, returns new UUID.
   - Expect: rows in `kudos`, `kudo_recipients`, `kudo_hashtags` (and `kudo_images` if paths provided).
   - Expect: `notifications` row with `type='kudos_received'`, `recipient_id=<otherUid>`.
2. **Other fetches the feed**
   - GET `/rest/v1/kudos_with_stats?...` — sees the new kudo with `hearts_count=0`.
3. **Other hearts the kudo**
   - POST `/rest/v1/kudo_hearts`.
   - Expect: `notifications` row with `type='kudos_liked'`, `recipient_id=<selfUid>`, `payload.liker_id=<otherUid>`.
4. **Repeat heart 4 more times (from 4 distinct users or same user on 5 distinct kudos from self)**
   - On the 5th cumulative heart across sender Self's kudos, trigger `maybe_grant_secret_box` mints a new `secret_boxes` row.
   - Expect: `notifications` row with `type='secret_box_granted'`, `payload.secret_box_id`.
5. **Self opens the box**
   - POST `/rest/v1/rpc/open_secret_box`.
   - Returns the updated row with `opened_at`, `prize_type='badge'`, `badge_kind`.
6. **Self collects the 6th distinct badge**
   - On the last `open_secret_box` that yields the 6th unique `badge_kind`, product logic (backend) inserts a `gift_redemptions` row.
   - Expect: `notifications` row with `type='badge_collected'`.

### INT-2 — Anonymity end-to-end

1. Self composes `kudoAnon` to Other.
2. Other queries `GET /rest/v1/kudos_feed?id=eq.<kudoAnon.id>`.
3. Assert: `sender_id` is `null`, `anonymous_alias` is `"Fan cuồng"`.
4. OutsiderC queries the same endpoint.
5. Assert: same redaction.
6. Self queries the same endpoint.
7. Assert: `sender_id` is `<selfUid>` (author sees own).

### INT-3 — Moderation → N5 → Community Standards

1. Admin sets `kudos.status = 'soft_hidden'` on `kudoActive` via service_role.
2. Trigger `notify_content_soft_hidden` fires.
3. Expect: `notifications` row with `type='content_soft_hidden'`, `recipient_id=<selfUid>`, `payload.kudo_id=<kudoActive.id>`.
4. Other queries `/rest/v1/kudos_feed?id=eq.<kudoActive.id>` → 0 rows.
5. Self queries the same → 1 row with `status='soft_hidden'`.

### INT-4 — Delete kudo + cascade

1. Self DELETEs `kudoActive`.
2. Expect: all child rows in `kudo_recipients`, `kudo_hashtags`, `kudo_hearts`, `kudo_images`, `kudo_moderation_events`, `kudo_reports` are gone.
3. Related notifications are preserved (not cascaded — the N1 on the recipient stays until they dismiss it).
   - Decision: keep notifications? If product wants to cascade-delete N1 too, add `ON DELETE CASCADE` to a new FK `notifications.payload.kudo_id` — out of scope for v1.

### INT-5 — Report flow

1. Other POSTs `kudo_reports` on `kudoActive`.
2. Expect: row inserted.
3. Other POSTs same report again → 409 (UNIQUE).
4. Admin (service_role) reads `kudo_reports WHERE kudo_id = kudoActive.id` → 1 row.
5. Admin sets `kudos.status = 'soft_hidden'` → Self gets N5 (see INT-3).

---

## Non-functional tests

### Performance

| ID | Target | Measure | Pass threshold |
|----|--------|---------|----------------|
| PERF_01 | Kudos feed pagination | p95 for `GET /rest/v1/kudos_with_stats?order=created_at.desc&Range:0-19` | < 200 ms |
| PERF_02 | Profile search | p95 for `ilike %q%` with trigram index | < 150 ms |
| PERF_03 | `open_secret_box` RPC | p95 latency under 10 concurrent callers | < 250 ms (each) |
| PERF_04 | Notifications first page | p95 | < 200 ms |

### Security audit

| ID | Scenario | Expected |
|----|----------|----------|
| SEC_01 | Attempt SELECT on `/rest/v1/kudos` with `authenticated` JWT | 403 / 42501 |
| SEC_02 | Attempt UPDATE on `secret_boxes` directly | 403 (no policy) |
| SEC_03 | Attempt INSERT on `notifications` with `authenticated` | 403 |
| SEC_04 | Attempt INSERT on `hashtags` with `authenticated` | 403 (policy removed 0027) |
| SEC_05 | Anonymous-kudo sender identity leak via `kudo_recipients` join | Not possible (0022 policy tightens) |
| SEC_06 | Admin review notification visible to non-admin | Expect the client query to filter with `type=neq.admin_review_request`. Plus backend ensures `admin_review_request` rows are only inserted for admin recipients. |

---

## Coverage summary

| Tag | Endpoints | Positive | Negative | Validation | Security | Total |
|-----|-----------|---------:|---------:|-----------:|---------:|------:|
| Auth | 4 | 4 | 5 | 0 | 0 | 9 |
| Profiles | 1 | 4 | 1 | 0 | 0 | 5 + 1 perf |
| Kudos (feed) | 2 | 3 | 1 | 0 | 3 | 7 |
| Kudos (delete) | 1 | 1 | 1 | 0 | 1 | 3 |
| create_kudo RPC | 1 | 3 | 1 | 12 | 0 | 16 + side-effects |
| Hearts | 2 | 3 | 2 | 0 | 1 | 6 + side-effects |
| Reports | 1 | 1 | 2 | 1 | 1 | 5 |
| Secret Boxes | 2 | 3 | 1 | 0 | 2 | 6 + concurrency |
| Notifications | 2 | 4 | 0 | 0 | 2 | 6 |
| Awards | 1 | 2 | 2 | 0 | 0 | 4 |
| Hashtags | 1 | 1 | 1 | 0 | 0 | 2 |
| Storage | 1 | 2 | 3 | 0 | 1 | 6 |
| Realtime | 1 | 3 | 2 | 0 | 0 | 5 |
| Integration scenarios | — | 5 | — | — | — | 5 |
| Performance | — | — | — | — | — | 4 |
| Security audit | — | — | — | — | 6 | 6 |

**Total ≈ 100 test cases** covering all client-facing endpoints + 5
end-to-end integration flows + performance + security audits.

---

## Recommended tooling

- **Supabase CLI** (`supabase db reset` + seed) for fixture management.
- **pgTAP** for in-database RLS / trigger unit tests.
- **Postman / Bruno / k6** for REST + realtime subscription suites.
- **Deno test** (if any Edge Functions are later added) for function-
  level tests.
- iOS side: **XCTest + RxTest** wraps these into integration tests
  against the staging Supabase project (per constitution IV).

---

## Next steps

- [ ] Wire these test cases into CI against the **staging** Supabase
      project. Never hit prod.
- [ ] Generate a fixture-seed SQL script in
      `supabase/seed.test.sql` that creates `selfUid`, `otherUid`,
      `kudoActive`, etc.
- [ ] When a `NotificationPayload*` shape changes, update the matching
      schema in [api-docs.yaml](api-docs.yaml) and any affected tests.
- [ ] Confirm `admin_review_request` insertion path (backend only).
