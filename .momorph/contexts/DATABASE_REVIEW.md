# Database Schema Review — Sun* Annual Awards 2025 (Web → iOS)

**Scope**: audit of [database-schema.sql](database-schema.sql) (current web schema,
post-21 migrations, snapshot 2026-04-23) against the 16 iOS screen specs in
[screen_specs/](screen_specs/), the project [constitution](../constitution.md)
(especially Principle V — Secure-by-Default), and the MoMorph DB guidelines.

**Date**: 2026-04-25
**Reviewer**: `/momorph.database`

Files untouched:
- [database-schema.sql](database-schema.sql) — web-production "truth" as requested
- [DATABASE_DESIGN.md](DATABASE_DESIGN.md) — existing ERD

This file is the **delta** — what's right, what's missing, what's risky. All
numbered findings map back to their spec / principle source so the issue can
be traced.

---

## TL;DR

The schema is **solid as a web MVP** but has **3 load-bearing gaps** before iOS
can ship safely:

| # | Severity | Issue | One-line fix |
|---|----------|-------|--------------|
| 1 | 🔴 CRITICAL | **Anonymity leak**: `kudos.sender_id` is readable by all authenticated users — any client can join to `profiles` and reveal the "anonymous" sender | Add a column-redacting view `kudos_view` + revoke SELECT on `public.kudos.sender_id` for `authenticated` role (see §1) |
| 2 | 🔴 CRITICAL | **No moderation status on `kudos`** — Community Standards says "Spam" + soft-hidden is a thing; Profile/Notifications specs show a `Spam` badge and N5 notification; schema has NO way to represent this | Add `kudos.status` enum + moderation trigger pipeline (see §3) |
| 3 | 🔴 CRITICAL | **Secret Box "UPDATE-to-open" RLS is exploitable** — a client can set `opened_at=now()` without getting any prize; there's no server-authoritative `open_secret_box` RPC | Revoke direct UPDATE; add `open_secret_box()` RPC that atomically locks, assigns prize server-side, updates `opened_at` (see §9) |

Beyond those, there are **5 missing tables / features** the iOS specs depend
on (notifications, badges_owned, kudo_reports, awards, spotlight/top-winners)
and a handful of convention / naming mismatches.

---

## Summary scorecard

| Area | Assessment |
|------|------------|
| Core kudos composition (create_kudo, hashtags, images, hearts) | 🟢 Good — well-validated SECURITY DEFINER function; tidy trigger for 5-image cap |
| Honour tier computation | 🟢 Good — `compute_honour_tier` + trigger is a clean pattern; thresholds (1/5/10/20) documented |
| Departments + hashtags seeding | 🟢 Good — bilingual, canonical |
| RLS on base tables | 🟡 Mostly correct, but **permissive SELECT on `kudos` bypasses anonymity** |
| Moderation / spam workflow | 🔴 Missing entirely |
| Secret Box prize pipeline | 🔴 Weak — client-driven UPDATE + no prize tracking |
| Notifications | 🔴 Missing entirely |
| Awards catalogue | 🟠 Missing |
| Badge collection tracking | 🟠 Missing (tied to secret_box reveals) |
| Search performance | 🟡 No trigram index on `profiles.display_name` |
| iOS-specific concerns (HEIC, realtime publication) | 🟡 Minor gaps |

---

## 🔴 CRITICAL findings

### §1. Anonymity leak on `kudos.sender_id`

**Source**: [view-kudo.md §Security](screen_specs/view-kudo.md) — explicitly
documents the load-bearing rule: "when `is_anonymous = true`, the server MUST
NOT return `sender_id` / name / avatar / department to non-author /
non-admin viewers."

**Current schema**:
```sql
CREATE POLICY kudos_select_authenticated ON public.kudos
  FOR SELECT TO authenticated USING (true);
```

Any authenticated user can `SELECT sender_id, is_anonymous FROM kudos` and
join to `profiles` to discover the real sender of any anonymous kudo.
**The `is_anonymous = true` flag is purely cosmetic today.**

**Why it matters**: a Sunner might send a Kudo anonymously to share honest
praise about a superior without social pressure. If the app leaks the real
identity, trust in the feature is broken AND Principle V (Secure-by-Default)
is violated.

**Proposed fix** (in priority order — pick ONE, not all three):

**Option A (recommended)** — server-side redaction view:

```sql
CREATE VIEW public.kudos_feed AS
SELECT
  k.id,
  k.title,
  k.body,
  k.is_anonymous,
  k.created_at,
  -- Sender fields are NULLed when anonymous AND the viewer is not the author
  CASE
    WHEN k.is_anonymous AND k.sender_id <> auth.uid()
    THEN NULL ELSE k.sender_id
  END AS sender_id,
  k.anonymous_alias AS displayed_sender_alias
FROM public.kudos k;

ALTER VIEW public.kudos_feed OWNER TO postgres;
GRANT SELECT ON public.kudos_feed TO authenticated;

-- Revoke direct SELECT on the underlying table for authenticated:
REVOKE SELECT ON public.kudos FROM authenticated;
-- (service_role + admin paths still have full access via SUPERUSER)
```

The iOS client (and the web client) must switch all reads from
`public.kudos` → `public.kudos_feed`. The `create_kudo` RPC path is
unaffected because it runs as SECURITY DEFINER.

**Option B** — column-level privileges (Postgres 16+):

```sql
REVOKE SELECT ON public.kudos FROM authenticated;
GRANT SELECT (id, title, body, is_anonymous, anonymous_alias, created_at)
  ON public.kudos TO authenticated;
-- sender_id intentionally withheld; clients must use kudos_feed or an RPC
```

Simpler, but clients still need a separate path to fetch their own kudos
(where they SHOULD see sender_id = themselves). A view with a CASE is
cleaner.

**Option C** — RLS that NULLs the column at read time:

Postgres RLS doesn't natively support column-level predicates in SELECT;
would require a security barrier view anyway. Falls back to Option A.

**Downstream impact**:

- Update `kudos_with_stats` view to reference `kudos_feed` instead of
  `kudos`.
- All iOS specs that read `kudos` (`home.md`, `profile-me.md`,
  `profile-other.md`, `sun-kudos.md`, `all-kudos.md`, `view-kudo.md`,
  `notifications.md`) need to switch endpoint from `kudos` to `kudos_feed`.

---

### §2. `kudo_recipients` leaks anonymity too

**Source**: same spec. Currently:
```sql
CREATE POLICY kudo_recipients_select ON public.kudo_recipients
  FOR SELECT TO authenticated USING (true);
```

Even if §1 is fixed, the **junction table** still exposes `recipient_id`
for every kudo — which is fine — but if combined with the underlying
`kudos.sender_id`, it enables "who sent what to whom" reconstruction for
anonymous kudos too.

**Proposed fix**: Option A's view should also JOIN and emit
`recipient_id` so clients never query the raw `kudo_recipients` table for
anonymous kudos. Alternatively, add a policy that restricts SELECT on
`kudo_recipients` only for rows whose parent kudo `is_anonymous = false`
OR the viewer is one of the endpoints:

```sql
DROP POLICY kudo_recipients_select ON public.kudo_recipients;

CREATE POLICY kudo_recipients_select ON public.kudo_recipients
  FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.kudos k
      WHERE k.id = kudo_recipients.kudo_id
        AND (
          k.is_anonymous = false
          OR k.sender_id = auth.uid()
          OR kudo_recipients.recipient_id = auth.uid()
        )
    )
  );
```

---

### §3. No moderation status on `kudos` — entire Community-Standards flow is DB-orphaned

**Sources**:
- [community-standards.md](screen_specs/community-standards.md) — canonical
  10-criterion `KudosSpamCriterion` taxonomy.
- [notifications.md](screen_specs/notifications.md) — N5 = "content
  soft-hidden" notification.
- [profile-me.md](screen_specs/profile-me.md) — shows a `Spam` status
  overlay on flagged kudos.
- [gui-loi-chuc-kudos.md](screen_specs/gui-loi-chuc-kudos.md) —
  server-side moderation may return `status = 'soft_hidden'` on
  creation.

**Current schema**: `kudos` is declared immutable ("UPDATE/DELETE denied
by RLS"). There is **no `status` column, no moderation table, no
soft-hide mechanic**. The entire Community Standards product flow has
nowhere to write its data.

**Proposed migration sketch**:

```sql
-- 1. Add the status enum
CREATE TYPE public.kudo_status AS ENUM ('active', 'soft_hidden', 'spam');

-- 2. Add the column (default active for backfill)
ALTER TABLE public.kudos
  ADD COLUMN status public.kudo_status NOT NULL DEFAULT 'active';

-- 3. Index for feed filter
CREATE INDEX kudos_status_created_at ON public.kudos (status, created_at DESC);

-- 4. RLS: non-authors see only active; authors see their own regardless
DROP POLICY kudos_select_authenticated ON public.kudos;  -- (replaced by kudos_feed view per §1)

-- 5. Moderation actions (backend only; write via service_role)
CREATE TABLE public.kudo_moderation_events (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  kudo_id       uuid NOT NULL REFERENCES public.kudos(id) ON DELETE CASCADE,
  prev_status   public.kudo_status NOT NULL,
  new_status    public.kudo_status NOT NULL,
  criterion     text,                              -- free text or slug of KudosSpamCriterion
  actor         text,                              -- 'system' | 'admin:<uuid>'
  created_at    timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX kudo_moderation_events_kudo_id ON public.kudo_moderation_events (kudo_id, created_at DESC);

-- 6. Trigger: when kudos.status changes, log an event + fire N5 notification
--    (details in the notifications section §6 below)
```

Then update Option A's view to include the status field and filter:

```sql
CREATE OR REPLACE VIEW public.kudos_feed AS
SELECT
  k.id, k.title, k.body, k.is_anonymous, k.anonymous_alias,
  k.status, k.created_at,
  CASE
    WHEN k.is_anonymous AND k.sender_id <> auth.uid()
    THEN NULL ELSE k.sender_id
  END AS sender_id
FROM public.kudos k
WHERE k.status = 'active'
   OR k.sender_id = auth.uid();   -- authors see their own soft-hidden content
```

---

### §4. `secret_boxes` UPDATE policy is exploitable

**Source**: [open-secret-box.md §Security](screen_specs/open-secret-box.md) —
server must be authoritative; client MUST NOT influence prize
assignment or bypass the RPC.

**Current schema**:
```sql
CREATE POLICY secret_boxes_open_self ON public.secret_boxes
  FOR UPDATE TO authenticated
  USING      (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());
```

A malicious client can:
- `UPDATE secret_boxes SET opened_at=now() WHERE user_id=auth.uid() AND opened_at IS NULL LIMIT 1;`
  and never receive any prize — that's fine (self-denial).
- But the schema has **no prize** to assign. Each box is pure
  `opened_at` — there's no `prize_kind` / `prize_name` column. So the
  client gets nothing either way, because the feature isn't actually
  implemented at the DB layer.

**Two problems at once**:
1. No prize tracking on `secret_boxes`.
2. No server-authoritative opening RPC.

**Proposed fix**:

```sql
-- Extend the table
ALTER TABLE public.secret_boxes
  ADD COLUMN prize_type  text  CHECK (prize_type IN ('badge', 'physical')),
  ADD COLUMN badge_kind  text  CHECK (badge_kind IN (
    'revival', 'touch_of_light', 'stay_gold', 'flow_to_horizon',
    'beyond_the_boundary', 'root_further'
  )),
  ADD COLUMN prize_name        text,
  ADD COLUMN prize_asset_key   text;

-- Enforce at-most-one-of semantics
ALTER TABLE public.secret_boxes
  ADD CONSTRAINT secret_boxes_prize_shape CHECK (
    (opened_at IS NULL  AND prize_type IS NULL AND badge_kind IS NULL)
    OR (opened_at IS NOT NULL AND prize_type IS NOT NULL)
  );

-- Revoke direct UPDATE from clients — opening goes through the RPC
DROP POLICY secret_boxes_open_self ON public.secret_boxes;

-- RPC: server assigns the prize atomically
CREATE OR REPLACE FUNCTION public.open_secret_box()
RETURNS public.secret_boxes
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  uid uuid := auth.uid();
  box secret_boxes%ROWTYPE;
  chosen_kind text;
BEGIN
  IF uid IS NULL THEN
    RAISE EXCEPTION 'open_secret_box: not authenticated';
  END IF;

  -- Pick the oldest unopened box FOR UPDATE SKIP LOCKED (concurrency-safe)
  SELECT * INTO box
  FROM public.secret_boxes
  WHERE user_id = uid AND opened_at IS NULL
  ORDER BY created_at ASC
  FOR UPDATE SKIP LOCKED
  LIMIT 1;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'open_secret_box: no unopened box for user';
  END IF;

  -- Pick a prize (placeholder — real policy is product-defined)
  chosen_kind := (ARRAY[
    'revival', 'touch_of_light', 'stay_gold',
    'flow_to_horizon', 'beyond_the_boundary', 'root_further'
  ])[1 + floor(random() * 6)::int];

  UPDATE public.secret_boxes
  SET opened_at  = now(),
      prize_type = 'badge',
      badge_kind = chosen_kind
  WHERE id = box.id
  RETURNING * INTO box;

  RETURN box;
END;
$$;

REVOKE ALL ON FUNCTION public.open_secret_box() FROM public;
GRANT  EXECUTE ON FUNCTION public.open_secret_box() TO authenticated;
```

Then the **reward pipeline** (when does a Sunner earn a box?) should be a
separate server trigger — see §5.

---

## 🟠 HIGH findings — missing tables / workflows

### §5. Secret Box grant pipeline — "5 hearts = 1 box" is not implemented

**Source**: [the-le.md](screen_specs/the-le.md) — "Cứ mỗi 5 lượt ❤️, bạn sẽ
được mở 1 Secret Box."

The schema has `secret_boxes` (the ledger) but no trigger that **creates**
a new row when a sender's cumulative heart count reaches a multiple of 5.

**Proposed**: trigger on `kudo_hearts` INSERT that counts total hearts on
the kudo's sender's kudos, and conditionally inserts a `secret_boxes` row
every time the counter crosses a new multiple of 5:

```sql
CREATE OR REPLACE FUNCTION public.maybe_grant_secret_box()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  sender uuid;
  total_hearts int;
  total_boxes  int;
BEGIN
  SELECT k.sender_id INTO sender FROM public.kudos k WHERE k.id = NEW.kudo_id;
  IF sender IS NULL THEN
    RETURN NEW;
  END IF;

  SELECT COUNT(*) INTO total_hearts
  FROM public.kudo_hearts h
  JOIN public.kudos k ON k.id = h.kudo_id
  WHERE k.sender_id = sender;

  SELECT COUNT(*) INTO total_boxes FROM public.secret_boxes WHERE user_id = sender;

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
```

**Concurrency note**: under heavy load two simultaneous hearts could race
and both see `(total_hearts/5) > total_boxes`, granting two boxes instead
of one. Mitigations: (a) SELECT FOR UPDATE on the sender's profile row
(serialize per user), or (b) UNIQUE constraint on `(user_id, ordinal)`
where ordinal is deterministic. v1 can accept occasional over-grants.

### §6. Notifications table — entirely missing

**Source**: [notifications.md](screen_specs/notifications.md) — 7 typed
rows, mark-all-read, unread count, Realtime live ticker, etc.

**Proposed**:

```sql
CREATE TYPE public.notification_type AS ENUM (
  'kudos_received',
  'kudos_liked',
  'secret_box_granted',
  'level_up',
  'content_soft_hidden',
  'badge_collected',
  'admin_review_request'
);

CREATE TABLE public.notifications (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  recipient_id  uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  type          public.notification_type NOT NULL,
  payload       jsonb NOT NULL,                 -- typed per `type` (kudoId, boxId, etc.)
  read_at       timestamptz,
  created_at    timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX notifications_recipient_created
  ON public.notifications (recipient_id, created_at DESC);
CREATE INDEX notifications_unread
  ON public.notifications (recipient_id) WHERE read_at IS NULL;

ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

CREATE POLICY notifications_select_self ON public.notifications
  FOR SELECT TO authenticated USING (recipient_id = auth.uid());

CREATE POLICY notifications_mark_read ON public.notifications
  FOR UPDATE TO authenticated
  USING      (recipient_id = auth.uid())
  WITH CHECK (recipient_id = auth.uid() AND read_at IS NOT NULL);
```

**Writer path**: backend triggers fire `notifications` inserts from
other tables (kudos INSERT → N1 for recipient; kudo_hearts INSERT for
someone else's kudo you're author of → N2 batched; secret_boxes INSERT
→ N3; honour_title change → N4; kudos status soft_hidden → N5; etc.).

**Admin-review row (N7) filtering**: the enum is declared but iOS v1
should not receive these. Put a WHERE clause into the iOS feed query
(`AND type <> 'admin_review_request'`) OR gate at the trigger (don't
insert N7 for non-admin recipients).

**Realtime**: add `ALTER PUBLICATION supabase_realtime ADD TABLE
public.notifications;` so the iOS bell dot + live prepend on
Notifications screen works.

### §7. Badges-owned table — missing

**Source**: [profile-me.md](screen_specs/profile-me.md),
[profile-other.md](screen_specs/profile-other.md),
[the-le.md](screen_specs/the-le.md).

The 6-icon badge set (REVIVAL / TOUCH OF LIGHT / STAY GOLD / FLOW TO
HORIZON / BEYOND THE BOUNDARY / ROOT FUTHER) is visible on profiles, but
there's no table linking user → badges owned.

**Option 1 (tight)** — derive from `secret_boxes`:

If every badge is earned solely through Secret Box reveals, Profile can
query `secret_boxes WHERE user_id = ? AND prize_type='badge' GROUP BY
badge_kind`. No new table needed.

**Option 2 (explicit)** — dedicated table:

```sql
CREATE TYPE public.badge_kind AS ENUM (
  'revival', 'touch_of_light', 'stay_gold',
  'flow_to_horizon', 'beyond_the_boundary', 'root_further'
);

CREATE TABLE public.badges_owned (
  user_id      uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  badge_kind   public.badge_kind NOT NULL,
  earned_at    timestamptz NOT NULL DEFAULT now(),
  secret_box_id uuid REFERENCES public.secret_boxes(id),
  PRIMARY KEY (user_id, badge_kind)
);
```

Recommend Option 1 (derive) for v1 — less redundancy, Secret Box ledger
already has everything.

### §8. Awards catalogue — missing

**Source**: [home.md](screen_specs/home.md) —
`supabase.from("awards").select(...).limit(3)` for teaser;
[award-detail.md](screen_specs/award-detail.md) — Option A bundles
content in the app, **Option B** uses a `awards` table.

**If Option A (bundled)**: no DB change; iOS just renders from a static
catalogue. But the web client may want Option B for editability.

**Suggested shape if Option B is adopted**:

```sql
CREATE TYPE public.award_kind AS ENUM (
  'mvp', 'best_manager', 'signature_creator',
  'top_project', 'top_project_leader', 'top_talent'
);

CREATE TABLE public.awards (
  kind              public.award_kind PRIMARY KEY,
  title_vi          text NOT NULL,
  title_en          text NOT NULL,
  description_vi    text NOT NULL,
  description_en    text NOT NULL,
  artwork_asset_key text NOT NULL,
  display_order     smallint NOT NULL,
  created_at        timestamptz NOT NULL DEFAULT now(),
  updated_at        timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.awards ENABLE ROW LEVEL SECURITY;
CREATE POLICY awards_select ON public.awards FOR SELECT TO authenticated USING (true);
```

### §9. Search performance — no trigram index on `profiles.display_name`

**Source**: [search-sunner.md](screen_specs/search-sunner.md) +
[gui-loi-chuc-kudos.md](screen_specs/gui-loi-chuc-kudos.md) — both rely on
`ilike("full_name", "%q%")`.

**Fix**:
```sql
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE INDEX profiles_display_name_trgm
  ON public.profiles USING gin (display_name gin_trgm_ops);
```

Without this, ILIKE with a leading `%` wildcard goes full table scan at
every keystroke of the debounced search. For a Sunner population of ~2k
this is tolerable; for 10k+ it's painful.

### §10. Kudo body length not bounded at DB level

**Source**: [community-standards.md](screen_specs/community-standards.md)
criterion #7 (min 30 chars), gui-loi-chuc-kudos.md (max ~1000 chars).

Client-side enforces min 30, but DB has no upper bound.

**Fix**:
```sql
ALTER TABLE public.kudos
  ADD CONSTRAINT kudos_body_length CHECK (char_length(btrim(body)) BETWEEN 30 AND 2000);
```

Note: if legacy rows exist with shorter bodies, add a `NOT VALID` +
later `VALIDATE CONSTRAINT` in 2 migrations. Also update the
`create_kudo` validator to mirror the bound.

### §11. No hashtag-count cap at DB layer

**Source**: [gui-loi-chuc-kudos.md](screen_specs/gui-loi-chuc-kudos.md) —
1 ≤ hashtags ≤ 5.

`create_kudo` enforces ≤ 5, but the `kudo_hashtags_insert` RLS allows
any sender to bulk insert. Consistency hole.

**Fix** — trigger mirroring `enforce_kudo_image_limit`:
```sql
CREATE OR REPLACE FUNCTION public.enforce_kudo_hashtag_limit()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  IF (SELECT COUNT(*) FROM public.kudo_hashtags WHERE kudo_id = NEW.kudo_id) >= 5 THEN
    RAISE EXCEPTION 'kudo_hashtags: each kudo may carry at most 5 hashtags';
  END IF;
  RETURN NEW;
END $$;

CREATE TRIGGER kudo_hashtags_limit
  BEFORE INSERT ON public.kudo_hashtags
  FOR EACH ROW
  EXECUTE FUNCTION public.enforce_kudo_hashtag_limit();
```

---

## 🟡 MEDIUM findings — mismatches & conventions

### §12. Field-name mismatches to align iOS ↔ DB

| iOS spec | Actual DB | Action |
|----------|-----------|--------|
| `full_name` | `profiles.display_name` | iOS layer should read as `display_name` |
| `award_title` (kudo) | `kudos.title` | Confirm `kudos.title` IS "Danh hiệu" (free text); update [gui-loi-chuc-kudos.md](screen_specs/gui-loi-chuc-kudos.md) field label accordingly |
| `kudo_attachments` bucket | `kudo-images` (hyphen) | iOS spec's bucket name must be updated in [gui-loi-chuc-kudos.md](screen_specs/gui-loi-chuc-kudos.md) §Security |
| `user_recent_searches` (optional v-next) | — | Local-only (UserDefaults) per spec — no action |
| `allowed_users` table | N/A (client-side allowlist only) | Matches the decision in [login.md](screen_specs/login.md) |

### §13. `kudos.title` default of "Lời cám ơn" vs spec requirement

Schema migration note: "title was added in 0007 (backfilled to 'Lời cám
ơn' in 0019 for legacy nulls)."

`create_kudo` requires `p_title` non-empty. So the default is only for
legacy data. That's fine. **But** iOS spec requires title 3–80 chars —
current DB has neither a min nor a max. Add a CHECK:

```sql
ALTER TABLE public.kudos
  ADD CONSTRAINT kudos_title_length CHECK (char_length(btrim(title)) BETWEEN 3 AND 80);
```

Again, legacy backfill value "Lời cám ơn" is only 10 chars — check your
actual data before applying this.

### §14. HEIC / HEIF support in Storage bucket

**Source**: [gui-loi-chuc-kudos.md](screen_specs/gui-loi-chuc-kudos.md) —
iOS clients commonly upload HEIC by default.

Current bucket allows `image/jpeg`, `image/png`, `image/webp`.

**Two options**:

- **Expand bucket**: add `image/heic`, `image/heif` to
  `allowed_mime_types`. Pro: preserves quality. Con: HEIC needs
  conversion for web display, and browser support is spotty.
- **Convert on iOS before upload**: downconvert to JPEG (quality ~0.85)
  client-side. Pro: universal. Con: some quality loss. **Recommended
  for v1 simplicity** — iOS clients routinely convert when sharing
  photos anyway.

Recommend: keep bucket as-is; iOS client converts.

### §15. Realtime publication not declared

**Source**: [notifications.md](screen_specs/notifications.md),
[sun-kudos.md](screen_specs/sun-kudos.md),
[all-kudos.md](screen_specs/all-kudos.md),
[view-kudo.md](screen_specs/view-kudo.md) — all rely on Supabase
Realtime.

Schema doesn't explicitly add tables to `supabase_realtime`
publication. Either the project relies on the default config or the
migration sets it up elsewhere.

**Add for completeness**:
```sql
ALTER PUBLICATION supabase_realtime
  ADD TABLE public.notifications, public.kudos, public.kudo_hearts;
```

### §16. Kudos are immutable — what about delete?

Current: `kudos` has no UPDATE/DELETE policies → only service_role can
mutate.

[view-kudo.md](screen_specs/view-kudo.md) discusses a delete flow (owner
+ admin). If product confirms delete is allowed in v1, add:

```sql
CREATE POLICY kudos_delete_self ON public.kudos
  FOR DELETE TO authenticated USING (sender_id = auth.uid());
```

Otherwise, close out the edit/delete action buttons in view-kudo.md to
just "Share" + "Report" for all viewers — consistent with the
schema's immutability.

### §17. `kudo_hearts` allows self-hearts

No CHECK preventing `sender(kudo_id) = user_id`. Product call — probably
fine; some products allow self-hearts as a "bookmark". Note for PM.

### §18. `updated_at` absent on mutable tables

MoMorph guidelines suggest handling `updated_at` in app code, not
triggers. Schema follows this correctly (no triggers) — but also no
`updated_at` column at all on mutable tables like `profiles`. If the
web/iOS app ever does "when was the profile last edited?", there's no
column for it. Minor — add if needed.

### §19. Gift redemption — ledger vs enforcement mismatch

```sql
user_id uuid NOT NULL UNIQUE  -- each Sunner can redeem at most one gift
```

Hard-codes the "one gift per Sunner" rule at DB level. Matches Thể lệ
and Notification N6 ("you collected 6 badges → BTC will deliver one
prize"). Good — but there's no RLS INSERT policy, so only
`service_role` writes. Confirm the backend has an Edge Function or
admin path that writes these rows. Otherwise the table is permanently
read-only.

---

## 🟢 LOW findings — nitpicks

### §20. UUID primary keys vs. MoMorph guidelines

Guidelines prefer `BIGSERIAL`. Schema uses UUIDs. In Supabase this is
idiomatic — intentional deviation. No action.

### §21. No audit log on `profiles.honour_title` changes

`sync_recipient_honour` silently UPDATEs profiles. If ever needed for
debugging / notifications, consider logging changes. For v1, the N4
"Level up" notification can be fired from this trigger.

### §22. Hashtag INSERT permissions

```sql
CREATE POLICY hashtags_insert_authenticated ON public.hashtags
  FOR INSERT TO authenticated WITH CHECK (true);
```

Any authenticated user can create a new hashtag row. The current 13
canonical hashtags are admin-curated — this policy contradicts that
curation. Either:
- Remove this policy (only service_role inserts), OR
- Keep it but monitor for spam hashtags, OR
- Rate-limit via a backend Edge Function.

Recommend: remove the INSERT policy — hashtags should be admin-only.

### §23. `auth.users` → `profiles` handoff

`handle_new_user()` trigger looks good. One subtle issue: it pulls
`department_id = NULL` on auto-provision. There's no UI path (per
specs) for a user to fill in their department post-sign-up — meaning
all auto-provisioned profiles will have `department_id = NULL`. If
departments are load-bearing (they're shown on profile cards), need a
strategy: map by email domain? Manual backfill? Clarify with product.

---

## 📋 Priority action table

| Priority | Finding | Action | Effort |
|---------:|---------|--------|:------:|
| 🔴 P0 | §1 — Anonymity leak | Add `kudos_feed` view + revoke `SELECT` on base `kudos` for `authenticated` | S |
| 🔴 P0 | §2 — `kudo_recipients` leak | Tighten RLS (anonymous-aware) | S |
| 🔴 P0 | §3 — Moderation status missing | Add `kudo_status` enum + column + `kudo_moderation_events` table | M |
| 🔴 P0 | §4 — Secret Box UPDATE policy | Replace with `open_secret_box` RPC; add prize columns | M |
| 🟠 P1 | §5 — Box grant pipeline (5 ❤ = 1 box) | Trigger on `kudo_hearts` | M |
| 🟠 P1 | §6 — Notifications table | Full schema + RLS + writer triggers | L |
| 🟠 P1 | §8 — Awards catalogue (if Option B) | Add `awards` table | S |
| 🟠 P1 | §10 — Body length CHECK | Add constraint (careful with legacy) | S |
| 🟠 P1 | §11 — Hashtag count cap trigger | Add trigger | S |
| 🟡 P2 | §9 — Trigram index on `display_name` | Add extension + GIN index | S |
| 🟡 P2 | §13 — `kudos.title` length CHECK | Add constraint | S |
| 🟡 P2 | §15 — Realtime publication | `ALTER PUBLICATION` | S |
| 🟡 P2 | §22 — Hashtag INSERT policy | Remove or restrict | S |
| 🟢 P3 | §7 — Derive badges_owned vs. explicit table | Product/PM decision | S |
| 🟢 P3 | §12 — Field naming alignment | iOS spec textual updates | S |
| 🟢 P3 | §14 — HEIC handling | iOS converts to JPEG client-side | N/A |
| 🟢 P3 | §16 — Kudo delete policy | Product decision | S |
| 🟢 P3 | §19 — Gift redemption writer | Backend config | S |
| 🟢 P3 | §23 — `department_id` backfill | Product + ops decision | M |

Effort key: **S** = < 1 day, **M** = 1–3 days, **L** = 3–5 days (incl.
migrations + tests + client cutover).

---

## 🧭 Recommendation

Before iOS ships:

1. **Resolve the 4 🔴 P0 findings** — they block secure production use.
   The anonymity leak alone is a legal / trust issue.
2. **Land §6 (notifications table)** — the iOS bell + inbox depend on
   it; the table doesn't exist anywhere today.
3. **Decide Option A vs. B for awards** (§8) and confirm whether
   `badges_owned` should be derived (§7).
4. Everything else in 🟡/🟢 is polish — can ship after.

After these changes, this schema is a good foundation for both the web
app and the iOS app. The bulk of the design (kudos composition, hashtags,
images, hearts, honour tier) is well thought out — the gaps are
overwhelmingly on the "moderation / notifications / secret-box-prize"
surface that the iOS specs surfaced for the first time.

---

## Suggested next steps

- [ ] Review this document with backend + product.
- [ ] For each 🔴 P0 finding, draft a migration file (e.g.
      `supabase/migrations/0022_anonymity_view.sql`).
- [ ] After migrations land, regenerate
      [database-schema.sql](database-schema.sql) as the new snapshot and
      refresh [DATABASE_DESIGN.md](DATABASE_DESIGN.md) with the new
      tables (notifications, moderation events, extended secret_boxes).
- [ ] Update affected iOS screen specs to reference `kudos_feed` view
      instead of `kudos` where they read from the feed.
