# Supabase Backend Guidelines

This document is the runtime guide for the server-side / data-layer work
that supports the AIDD-SAA-2025 iOS app. The backend is **Supabase**
(Postgres + Auth + Storage + Realtime + Edge Functions). There is no
bespoke Node/Next.js server in this project.

This guide implements, not replaces, the constitution at
`.momorph/constitution.md` (especially Principles I, IV, V). When in
conflict, the constitution wins.

---

## 1. Supabase Topology

- **One Supabase project per environment**: `dev`, `staging`, `prod`.
- **Keys the iOS app may use**:
  - `SUPABASE_URL` (public, bundled).
  - `SUPABASE_ANON_KEY` (public, bundled, protected by RLS).
- **Keys the iOS app MUST NEVER contain** (constitution V):
  - `SUPABASE_SERVICE_ROLE_KEY`. Lives only in CI secrets and Edge
    Functions.
- The `SupabaseClient` instance is constructed once at app launch in
  `App/`; injected downstream per Principle I (no global read).

---

## 2. Schema & Migrations

- Migrations are SQL files under `supabase/migrations/` managed via the
  Supabase CLI. Never edit production schema by hand through the
  dashboard — if you do, immediately back-fill the migration file and
  commit it.
- Naming: `YYYYMMDDHHMMSS_<snake_case_description>.sql`.
- Every new table MUST:
  1. Have a primary key (`uuid default gen_random_uuid()` preferred).
  2. Declare `created_at timestamptz not null default now()` and, if the
     row is mutable, `updated_at timestamptz`.
  3. Have **Row Level Security enabled** (`alter table X enable row level
     security;`) in the same migration that creates it.
  4. Ship with explicit `policy` statements (see §3).
- Destructive changes (drop column, type change) MUST be split into an
  additive migration, app deploy, and a follow-up cleanup migration.

---

## 3. Row Level Security (Principle V — NON-NEGOTIABLE)

- A table without RLS policies is **broken**, regardless of whether tests
  pass. Every `select`, `insert`, `update`, `delete` path needs a policy.
- Default posture: **deny-all**, then add narrowly scoped allow policies.
- Policy template for per-user owned rows:

  ```sql
  create policy "owner can select"
    on public.profiles for select
    using (auth.uid() = user_id);

  create policy "owner can update"
    on public.profiles for update
    using (auth.uid() = user_id)
    with check (auth.uid() = user_id);
  ```

- Policies MUST have integration tests hitting the Supabase REST API with
  both an authorized and an unauthorized JWT. Passing only with the
  service role is not acceptance.
- Storage buckets: same rule — create bucket, mark not-public, write
  policies explicitly.

---

## 4. Data Access from the iOS App

All data access goes through the `Data/Remote/` layer. Presentation and
Domain layers MUST NOT import `Supabase`.

```swift
// Data/Remote/Profiles/ProfileRemoteDataSource.swift
struct ProfileRemoteDataSource: ProfileRemoteDataSourceProtocol {
    let client: SupabaseClient

    func fetchProfile(userId: UUID) -> Single<ProfileDTO> {
        Single.create { single in
            Task {
                do {
                    let dto: ProfileDTO = try await client
                        .from("profiles")
                        .select()
                        .eq("user_id", value: userId.uuidString)
                        .single()
                        .execute()
                        .value
                    single(.success(dto))
                } catch {
                    single(.failure(error))
                }
            }
            return Disposables.create()
        }
    }
}
```

Rules:

- Use the SDK's parameterized query APIs. **Never** concatenate user
  input into filters or raw SQL.
- DTOs live next to the data source; map to Domain entities in the
  Repository implementation.
- Wrap `async` SDK calls into `Single`/`Completable` at the data-source
  boundary so everything above stays Rx (Principle III).
- Error surface: translate Supabase errors into domain-specific errors
  in the Repository. Views never see a `PostgrestError`.

---

## 5. Auth

- Use `supabase.auth` APIs exclusively. Do NOT roll custom password
  hashing or token minting.
- Persist the session via Supabase SDK defaults; override storage to the
  iOS Keychain for session tokens (constitution V — Storage rule).
- Token refresh: let the SDK handle it. Subscribe to
  `auth.authStateChanges` and re-publish as an `Observable<AuthState>`
  to the Domain layer.
- On sign-out: clear the Keychain, reset any in-memory caches, and
  return the user to the sign-in screen.

---

## 6. Edge Functions (when needed)

Use Edge Functions for:

- Operations that require the service role (e.g. admin actions, webhook
  handlers).
- Aggregations or multi-table writes that shouldn't round-trip to the
  client.
- Third-party API calls where the API key must be hidden.

Rules:

- Deno + TypeScript. File lives at `supabase/functions/<name>/index.ts`.
- Validate all inputs with a schema (e.g. `zod`). Reject unknown fields.
- Return typed JSON; include a stable `code` string for errors so the
  iOS Domain layer can switch on it.
- Unit-test with `deno test`. Integration-test by invoking the deployed
  function against a staging project.

---

## 7. Secrets & Configuration

- iOS: `Config/*.xcconfig` per environment, injected into `Info.plist`.
  `.xcconfig` files that contain secrets are gitignored; a
  `Config/Template.xcconfig` with blank values is committed.
- Edge Functions / CI: Supabase project secrets (`supabase secrets set`)
  or GitHub Actions secrets. Never commit.
- Key rotation procedure lives at `docs/runbooks/rotate-supabase-keys.md`
  (create on first rotation).

---

## 8. Observability

- Edge Functions log via `console.log`; logs show in Supabase dashboard.
  Never log request bodies containing PII or tokens.
- iOS Data layer emits `OSLog` breadcrumbs at category `data.supabase`
  for every request (start, end, duration). Bodies logged only at
  `.debug` level, marked `.private`.
- Track latency and error rate; define SLOs per feature in its
  `spec.md`.

---

## 9. Testing (Principle IV)

- **Contract tests**: for every Repository implementation, an integration
  test hits a **throwaway Supabase test project** (seeded per-run) or a
  local PostgREST stub. Run in CI against the staging project on merges
  to `main`.
- **Policy tests**: for each RLS policy, assert (a) authorized user
  succeeds, (b) unauthorized user is denied with the expected error
  code, (c) anonymous caller is denied.
- **Edge Function tests**: `deno test` in CI plus at least one end-to-end
  invocation test per deployable function.
- No production credentials in any test suite — CI provides a dedicated
  service-role key for the staging project, never `prod`.
