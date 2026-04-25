# Database Design — Sun\* Annual Awards 2025 (post-iOS fixes)

Snapshot ERD of the public schema **after migrations 0001–0028**. Source of
truth for table shapes and relationships lives in
[database-schema.sql](database-schema.sql). See
[DATABASE_REVIEW.md](DATABASE_REVIEW.md) for the rationale behind the
0022–0028 changes.

## What changed (0022–0028)

- **0022**: `kudo_status` enum + `kudos.status` column; `kudos_feed` view with
  anonymity redaction + status filter; `kudo_moderation_events` audit table.
- **0023**: `badge_kind` enum; prize columns on `secret_boxes`;
  `open_secret_box()` RPC (SECURITY DEFINER, atomic); grant-on-heart trigger.
- **0024**: `notification_type` enum; `notifications` table; 6 writer
  triggers; Realtime publication wiring.
- **0025**: `award_kind` enum; `awards` catalogue table (bilingual, seeded
  with 6 kinds).
- **0026**: length CHECKs on `kudos.body` + `kudos.title`; hashtag-cap
  trigger.
- **0027**: `pg_trgm` extension + GIN index on `profiles.display_name`;
  removed `hashtags_insert_authenticated` policy.
- **0028**: author-DELETE on `kudos`; `kudo_reports` table.

## Reading the diagram

- **`||--||`** = one-to-one (e.g. `auth_users` ↔ `profiles`)
- **`||--o{`** = one-to-many (standard FK)
- **PK** marks the primary key. Composite-PK columns on junction tables are
  also FKs to their parent tables.

## ERD

```mermaid
erDiagram
    auth_users ||--|| profiles : "owns"
    departments ||--o{ profiles : "groups"

    profiles ||--o{ kudos : "sends"
    profiles ||--o{ kudo_recipients : "receives"
    profiles ||--o{ kudo_hearts : "hearts"
    profiles ||--o{ kudo_reports : "reports"
    profiles ||--o{ gift_redemptions : "earns"
    profiles ||--o{ secret_boxes : "owns"
    profiles ||--o{ notifications : "receives"

    kudos ||--|| kudo_recipients : "delivered_to"
    kudos ||--o{ kudo_hashtags : "tagged_with"
    kudos ||--o{ kudo_hearts : "receives"
    kudos ||--o{ kudo_images : "attaches"
    kudos ||--o{ kudo_moderation_events : "audits"
    kudos ||--o{ kudo_reports : "is_reported_in"

    hashtags ||--o{ kudo_hashtags : "categorises"

    awards {
        award_kind kind PK "enum: mvp / best_manager / signature_creator / top_project / top_project_leader / top_talent"
        text title_vi
        text title_en
        text description_vi
        text description_en
        text artwork_asset_key
        smallint display_order
        timestamptz created_at
        timestamptz updated_at
    }

    auth_users {
        uuid id PK "supabase managed"
        text email
        jsonb raw_user_meta_data
    }

    departments {
        uuid id PK
        text code UK "49 canonical Sun* codes"
        text name_vi
        text name_en
        timestamptz created_at
    }

    profiles {
        uuid id PK "references auth.users"
        text email
        text display_name "trigram-indexed (0027)"
        text avatar_url
        uuid department_id FK
        honour_title honour_title "enum: Legend/Rising/Super/New Hero"
        timestamptz created_at
    }

    hashtags {
        uuid id PK
        text slug UK
        text label_vi
        text label_en
        timestamptz created_at
    }

    kudos {
        uuid id PK
        uuid sender_id FK "REDACTED in kudos_feed when is_anonymous"
        text body "30..2000 chars (0026)"
        text title "3..80 chars (0026)"
        boolean is_anonymous
        text anonymous_alias "2..40 chars when anon"
        kudo_status status "enum: active / soft_hidden / spam (0022)"
        timestamptz created_at
    }

    kudo_recipients {
        uuid kudo_id PK
        uuid recipient_id PK
    }

    kudo_hashtags {
        uuid kudo_id PK
        uuid hashtag_id PK
    }

    kudo_hearts {
        uuid kudo_id PK
        uuid user_id PK
        timestamptz created_at
    }

    kudo_images {
        uuid id PK
        uuid kudo_id FK
        text url "supabase storage path"
        smallint position "0..4"
        timestamptz created_at
    }

    kudo_moderation_events {
        uuid id PK
        uuid kudo_id FK
        kudo_status prev_status
        kudo_status new_status
        text criterion "KudosSpamCriterion slug or free text"
        text actor "system | admin:uuid"
        timestamptz created_at
    }

    kudo_reports {
        uuid id PK
        uuid kudo_id FK
        uuid reporter_id FK
        text reason_slug
        text note
        timestamptz created_at
    }

    notifications {
        uuid id PK
        uuid recipient_id FK
        notification_type type "enum: 7 kinds (0024)"
        jsonb payload
        timestamptz read_at
        timestamptz created_at
    }

    gift_redemptions {
        uuid id PK
        uuid user_id FK "UNIQUE — 1 gift per Sunner"
        text gift_name
        integer quantity "default 1"
        text source "default secret_box"
        timestamptz redeemed_at
        timestamptz created_at
    }

    secret_boxes {
        uuid id PK
        uuid user_id FK
        timestamptz opened_at "null when unopened"
        text prize_type "badge | physical (0023)"
        badge_kind badge_kind "enum: 6 SAA icons (0023)"
        text prize_name
        text prize_asset_key
        timestamptz created_at
    }
```

## Views (not shown in the diagram — they wrap `kudos`)

| View | Purpose | Introduced by |
|------|---------|---------------|
| `public.kudos_feed` | Anonymity-redacted + status-filtered read surface for all clients; the ONLY way `authenticated` can SELECT from `kudos` (direct SELECT is revoked) | Migration 0022 |
| `public.kudos_with_stats` | Convenience wrapper: `kudos_feed` + precomputed `hearts_count`. Used by Home teaser, Sun\*Kudos, All Kudos, and View kudo. | Updated in 0022 (previously wrapped `kudos` directly) |

## Security-relevant notes

1. **Anonymity boundary** is the `kudos_feed` view, not RLS — `sender_id` is
   `NULL`-masked server-side for non-author viewers when `is_anonymous =
   true`. Corresponding spec: [view-kudo.md](screen_specs/view-kudo.md).
2. **Secret Box prize assignment** is the `open_secret_box()` RPC, not a
   client UPDATE — clients cannot fabricate prizes. Corresponding spec:
   [open-secret-box.md](screen_specs/open-secret-box.md).
3. **Notifications** are INSERTed exclusively by trigger functions running
   as SECURITY DEFINER; clients can only `SELECT` own rows and `UPDATE
   read_at`. Corresponding spec: [notifications.md](screen_specs/notifications.md).
4. **Hashtag catalogue** (0027) is admin-curated — authenticated clients
   cannot create rows. The iOS `HashtagPickerSheet` in
   [gui-loi-chuc-kudos.md](screen_specs/gui-loi-chuc-kudos.md) should
   therefore NOT expose a "create new hashtag" affordance.
5. **Kudo immutability** is partially relaxed (0028) — the author can
   DELETE their own kudos. The `view-kudo.md` action-button matrix
   (Owner → Delete + Share; Viewer → Share + Report) is now backed by the
   `kudo_reports` table and the new DELETE policy. `UPDATE` on kudos
   remains service_role only (no client-edit flow in v1).
