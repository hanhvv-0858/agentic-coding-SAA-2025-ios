# Implementation Plan: M1 — Authentication

**Frame**: `8HGlvYGJWq-authentication` (Login + Access denied)
**Date**: 2026-04-25
**Spec**: [spec.md](spec.md)
**Roadmap**: [IMPLEMENTATION_ROADMAP.md § M1](../../contexts/IMPLEMENTATION_ROADMAP.md)
**Status**: Draft

---

## Summary

Deliver the unauthenticated stack of the SAA 2025 iOS app: a Sunner taps
**LOGIN With Google**, completes Google OAuth via
`ASWebAuthenticationSession`, lands on Home if their email domain is
allowlisted, or sees Access denied (with the session purged) if not.
Language switching (VN/EN) and lifecycle session restore are bundled in.
M1 also lands the **shared scaffolding** the rest of the app will reuse:
`AuthRepository` + `KeychainSessionStorage`, `AppRouter` wiring,
`ErrorStateView`, `TopNavigation`, `PrimaryButton`, `LanguageSwitcherChip`,
`LanguagePickerSheet`.

Because this is the first feature shipped, M1 carries an outsized share
of cross-cutting scaffolding — the plan intentionally calls these out so
later milestones don't re-litigate them.

---

## Technical Context

| | |
|---|---|
| **Language/Framework** | Swift 5.9+ / SwiftUI (iOS 17+, pending TODO(iOS_DEPLOYMENT_TARGET)) |
| **Primary deps** | `RxSwift 6.7.1` (`RxSwift`, `RxRelay`, `RxCocoa`), `supabase-swift 2.30.0` (`Supabase` product) |
| **System frameworks** | `AuthenticationServices` (`ASWebAuthenticationSession`), `Security` (Keychain), `Combine` (only at the SwiftUI bridge) |
| **Backend** | Supabase Auth (Google provider) — no Edge Functions needed for M1 |
| **Reactive model** | RxSwift across layer boundaries; Swift Concurrency only inside `SupabaseAuthDataSource` to bridge `async` SDK calls into `Single`/`Observable` |
| **Testing** | XCTest + RxTest/RxBlocking (unit + Rx ViewModel); XCUITest (US1 happy-path + US2 disallowed-domain) |
| **Architecture** | Clean Architecture: Presentation → Domain ← Data |
| **Feature-specific deviations** | None planned. All Open-Questions answers (Q1–Q5 in spec.md) are needed before implementation closes, but none block start of work. |

---

## Constitution Compliance Check

*GATE — must pass before merge.*

- [x] **I. Clean Architecture** — `Presentation/Auth/*` depends on `Domain/UseCases/*` only via protocols; `Domain` imports no Supabase/Rx-Cocoa types; `Data/Auth/*` is the only place `import Supabase` exists.
- [x] **II. SwiftUI-First & HIG** — `LoginView` / `AccessDeniedView` / `NotFoundView` built in SwiftUI; Dynamic Type (AX5), Light+Dark via semantic colours, VoiceOver labels per spec, HIG-minimum touch targets, every user-facing string in `Localizable.xcstrings`.
- [x] **III. Reactive Data Flow with RxSwift** — `AuthRepository.observeSession() -> Observable<AuthState>`; `LoginViewModel` exposes `Driver`/`Signal` outputs; SwiftUI consumes via `LoginStateAdapter: ObservableObject` (the only place `Combine` is allowed).
- [x] **IV. Test-First** — RxTest scenarios for every US acceptance criterion are written **before** the corresponding ViewModel/UseCase impl (Red → Green → Refactor). `RLSTests` for `profiles` (anon-denied + owner-allowed reads) added alongside Data layer.
- [x] **V. Secure-by-Default** — anon key only in bundle; tokens in Keychain (`AccessibleAfterFirstUnlockThisDeviceOnly`); `signOut()` MUST be called before navigating to Access denied; logs use `.private` interpolation; no PII in analytics; PKCE `code_verifier` lifetime is SDK-managed (Keychain if persisted).

**Violations**: none.

---

## Architecture Decisions

### Presentation Layer (SwiftUI + RxSwift)

**New screens**

| Screen | View | ViewModel | StateAdapter | Route |
|---|---|---|---|---|
| Login | `LoginView` | `LoginViewModel` | `LoginStateAdapter` | `.login` |
| Access denied | `AccessDeniedView` | `AccessDeniedViewModel` | none (single `Signal<Void>`) | `.accessDenied` |
| Not Found | `NotFoundView` | `NotFoundViewModel` | none | `.notFound(source:)` |

**ViewModel contracts** — locked from spec.md:

- `LoginViewModel`: in `signInTapped`, `languageTapped`, `oauthCallback`; out `isLoading`, `selectedLanguage`, `errorMessage`, `navigateHome`, `navigateAccessDenied`, `presentLanguageSheet`.
- `AccessDeniedViewModel`: in `primaryTapped`, `backTapped`; out `navigateLogin` (merged).
- `NotFoundViewModel`: in `primaryTapped`; out `navigateRoot` (resets to Login if signed-out, Home if signed-in — read from `AuthStore`).

**Navigation** — `AppRouter` already exists; this milestone wires its `AuthStore` subscription:

```swift
authStore.state
    .observe(on: MainScheduler.instance)
    .map { state -> AppRoute in
        switch state {
        case .signedIn: return .home
        case .signedOut: return .login
        case .unknown:   return .splash   // brief; AppRouter renders ProgressView
        }
    }
    .bind(to: router.currentRoute)
```

**Shared components introduced this milestone** (re-used by ≥3 future screens):

- `TopNavigation` (organism) — used by Access denied, Not Found, M2 Notifications, M3 Profile.
- `BackIconButton`, `PrimaryButton` (atoms) — global.
- `ErrorStateView` (organism) — title + divider + subtitle + illustration + primary button. Backs Access denied AND Not Found via the same component (frame analysis says the illustration asset is shared).
- `LanguageSwitcherChip` (molecule) + `LanguagePickerSheet` (modal sheet) — used by Login, Home, ProfileMe.

**HIG / a11y checklist (per screen)**

- `accessibilityLabel` keys defined in `Localizable.xcstrings` (see spec.md §UI/UX).
- Touch targets: enforce HIG minimum on every tap area; verified in XCUITest via `accessibilityFrame.size`.
- VoiceOver order asserted explicitly by `accessibilitySortPriority` where SwiftUI default order is wrong.
- Reduced-motion: no shimmer/fade; OAuth sheet uses system transition.

### Domain Layer

**Use cases (new)**

| Use case | Signature | Replaces |
|---|---|---|
| `SignInWithGoogleUseCase` | `execute() -> Single<AuthSession>` | n/a |
| `CheckEmailDomainUseCase` | `execute(_ session: AuthSession) -> Result<AuthSession, AuthError.disallowedDomain>` | n/a |
| `SignOutUseCase` | `execute() -> Completable` | n/a |
| `ObserveSessionUseCase` | `execute() -> Observable<AuthState>` | n/a — wraps `AuthRepository.observe()` |
| `RestoreSessionUseCase` | `execute() -> Single<AuthState>` | called once on app launch |
| `SetAppLanguageUseCase` | `execute(_ lang: AppLanguage)` | wraps `LocaleStore.set` (kept thin for testability) |

**Entities (already scaffolded in M0; verify shape matches spec)**

- `AppLanguage` ✅ (M0)
- `AllowedEmailDomains` ✅ (M0)
- `AuthSession`, `AuthUser` ✅ (M0) — `AuthUser.emailDomain` MUST be deterministic per spec.md (last-`@` substring, NFC, lowercase). Add unit test.
- `AuthState` ✅ (M0; lives in `AuthStore`)
- `AuthError` (NEW): `.cancelled`, `.network`, `.disallowedDomain`, `.serviceUnavailable`, `.unknown(Error)`.

**Repository protocol (Domain)**

```swift
protocol AuthRepository {
    func observe() -> Observable<AuthState>
    func signInWithGoogle() -> Single<AuthSession>
    func exchangeCallback(_ url: URL) -> Single<AuthSession>
    func signOut() -> Completable
    func restoreSession() -> Single<AuthState>
}
```

**Validation at Domain boundary**

- `CheckEmailDomainUseCase` rejects: missing `email` claim, empty `emailDomain`, `emailDomain` not in `AllowedEmailDomains`.
- `oauthCallback` URLs not matching configured `OAUTH_REDIRECT_URL` are filtered upstream by `AuthRepository.exchangeCallback` (returns `.cancelled` instead of `.unknown`).

### Data Layer (Supabase)

**Tables touched**: NONE for M1. Authentication state lives in `auth.users`; `profiles` is read in M3. The Authentication RLS gate is implicit — every other table the user can reach has RLS enabled per migrations 0022–0028.

**Files**

- `Data/Repositories/AuthRepositoryImpl.swift` — composes data source + Keychain + emits to `AuthStore`.
- `Data/Remote/Auth/SupabaseAuthDataSource.swift` — wraps `supabase.auth` SDK; bridges `async`/`AsyncStream` → Rx via `Single.create`/`Observable.create`.
- `Data/Local/Auth/KeychainSessionStorage.swift` — `Security` framework; `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`; service = bundle ID, account = `"sb.session"`. Stores serialised `AuthSession` (Codable).
- `Data/Remote/Auth/AuthDTO.swift` — maps `Supabase.Session` → `AuthSession` entity. NEVER copies email into logs.

**SDK boundary discipline**

- `subscribe(on: ConcurrentDispatchQueueScheduler.io)` for network calls.
- `observe(on: MainScheduler.instance)` before reaching the View layer.
- A single `DisposeBag` lives in each ViewModel; the Repository layer also owns one for the auth-state stream.

### Integration Points

- **Supabase services**: Auth only. (Postgres + Realtime arrive in M2; Storage in M3.)
- **Shared components consumed downstream**: see Presentation table above.
- **Secrets**: no new keys. M1 uses `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `ALLOWED_EMAIL_DOMAINS`, `OAUTH_REDIRECT_URL` — already wired in M0.

---

## Project Structure

### Documentation

```text
.momorph/specs/8HGlvYGJWq-authentication/
├── spec.md          # ✅ reviewed
├── plan.md          # this file
├── tasks.md         # next step (/momorph.tasks)
└── research.md      # not needed — spec + roadmap give enough context
```

### Source code (paths to land in M1)

```text
AIDD-SAA-2025/
├── App/
│   └── AIDD_SAA_2025App.swift                    # MODIFY — replace ContentView with RootView consuming AppRouter
├── Core/
│   ├── Config/AppConfig.swift                    # ✅ M0
│   ├── DI/Container.swift                        # MODIFY — register AuthRepository, KeychainSessionStorage, use cases
│   └── Logger.swift                              # ✅ M0
├── Domain/
│   ├── Entities/
│   │   ├── AuthError.swift                       # NEW
│   │   ├── AuthSession.swift                     # ✅ M0 (verify emailDomain rule)
│   │   ├── AppLanguage.swift                     # ✅ M0
│   │   └── AllowedEmailDomains.swift             # ✅ M0
│   ├── Repositories/
│   │   └── AuthRepository.swift                  # NEW (protocol)
│   ├── Stores/
│   │   ├── AuthStore.swift                       # ✅ M0
│   │   └── LocaleStore.swift                     # ✅ M0
│   └── UseCases/
│       ├── SignInWithGoogleUseCase.swift         # NEW
│       ├── CheckEmailDomainUseCase.swift         # NEW
│       ├── SignOutUseCase.swift                  # NEW
│       ├── ObserveSessionUseCase.swift           # NEW
│       ├── RestoreSessionUseCase.swift           # NEW
│       └── SetAppLanguageUseCase.swift           # NEW
├── Data/
│   ├── Repositories/
│   │   └── AuthRepositoryImpl.swift              # NEW
│   ├── Remote/Auth/
│   │   ├── SupabaseAuthDataSource.swift          # NEW
│   │   └── AuthDTO.swift                         # NEW
│   └── Local/Auth/
│       └── KeychainSessionStorage.swift          # NEW
├── Presentation/
│   ├── Shared/
│   │   ├── Navigation/
│   │   │   ├── AppRoute.swift                    # ✅ M0
│   │   │   ├── AppRouter.swift                   # MODIFY — bind to AuthStore (see snippet above)
│   │   │   └── AppTab.swift                      # ✅ M0 (unused until M2)
│   │   └── Components/
│   │       ├── TopNavigation.swift               # NEW
│   │       ├── BackIconButton.swift              # NEW
│   │       ├── PrimaryButton.swift               # NEW
│   │       ├── ErrorStateView.swift              # NEW
│   │       ├── LanguageSwitcherChip.swift        # NEW
│   │       └── LanguagePickerSheet.swift         # NEW
│   ├── Auth/
│   │   ├── Views/
│   │   │   ├── LoginView.swift                   # NEW
│   │   │   ├── AccessDeniedView.swift            # NEW
│   │   │   └── NotFoundView.swift                # NEW
│   │   └── ViewModels/
│   │       ├── LoginViewModel.swift              # NEW (protocol + impl)
│   │       ├── LoginStateAdapter.swift           # NEW (Rx → @Published bridge)
│   │       ├── AccessDeniedViewModel.swift       # NEW
│   │       └── NotFoundViewModel.swift           # NEW
│   └── Root/
│       └── RootView.swift                        # NEW — replaces placeholder ContentView
└── Resources/
    ├── Localizable.xcstrings                     # MODIFY — add 12 keys (see spec.md §UI/UX)
    └── Assets.xcassets/
        └── not_found_illustration.imageset/      # NEW asset (download via momorph.get_media_files)

AIDD-SAA-2025Tests/
├── Domain/
│   ├── Entities/
│   │   └── AuthSessionTests.swift                # NEW (emailDomain computation)
│   └── UseCases/
│       ├── CheckEmailDomainUseCaseTests.swift    # NEW
│       └── ObserveSessionUseCaseTests.swift      # NEW
├── Presentation/Auth/
│   ├── LoginViewModelTests.swift                 # NEW (RxTest TestScheduler)
│   └── AccessDeniedViewModelTests.swift          # NEW
└── Data/Auth/
    ├── KeychainSessionStorageTests.swift         # NEW (uses fresh Keychain access group per test)
    └── AuthRepositoryImplTests.swift             # NEW (mocked SupabaseAuthDataSource)

AIDD-SAA-2025UITests/
└── Auth/
    ├── LoginUITests.swift                        # NEW — US1 happy path
    └── AccessDeniedUITests.swift                 # NEW — US2 disallowed domain
```

### Dependencies — none added in M1

`Package.resolved` already pins `supabase-swift 2.30.0` and `RxSwift 6.7.1` from M0. **No new SPM packages.**

---

## Implementation Strategy

### Vertical-slice ordering

Deliver in this order so each PR is a usable, mergeable increment:

| Phase | PR | What lands | Visible result | Tests |
|---|---|---|---|---|
| **0** | PR-M1.0 | Asset prep (`not_found_illustration` exported via `get_media_files`); empty `Localizable.xcstrings` keys with VN+EN copy | Asset visible in Xcode, no behaviour | n/a |
| **1** | PR-M1.1 | `AuthError`, `AuthRepository` protocol, **`KeychainSessionStorage`** + tests, `AuthRepositoryImpl` skeleton with `observe()` only, DI wiring | App still shows splash; M0 smoke test still passes | Keychain unit tests; RxTest for `observe()` emission |
| **2** | PR-M1.2 (US1) | `SupabaseAuthDataSource` (full), `SignInWithGoogleUseCase`, `RestoreSessionUseCase`, `LoginViewModel`+adapter+`LoginView`, `AppRouter` ↔ `AuthStore` wiring, `RootView` | A `@sun-asterisk.com` user signs in → blank Home placeholder | RxTest US1 AS1–AS5; XCUITest happy path |
| **3** | PR-M1.3 (US2) | `CheckEmailDomainUseCase`, `SignOutUseCase`, `AccessDeniedView`+VM, `ErrorStateView`, `TopNavigation`, `BackIconButton`, `PrimaryButton` | Disallowed domain → Access denied → back to Login | RxTest US2 AS1–AS4; XCUITest disallowed domain |
| **4** | PR-M1.4 (US3) | `LanguageSwitcherChip`, `LanguagePickerSheet`, `SetAppLanguageUseCase`, localisation keys live | Tap chip → pick VN/EN → instant re-render | RxTest US3 AS1–AS5; snapshot test of both locales |
| **5** | PR-M1.5 (US4 + Polish) | Lifecycle hooks (foreground/background), Reduce-Motion respect, NotFoundView, accessibility audit, analytics events, security review checklist | Backgrounded → restored without flash; 404 deep-links land on NotFound | RxTest US4 AS1–AS3; VoiceOver smoke; SEC_02 (no residual token) |

**Branch naming**: `feat/m1.{1-5}-<short-desc>` per Constitution §Workflow.

### Phase 0 — Asset Preparation

```text
1. Run `mcp__momorph__get_media_files` for frame `8HGlvYGJWq` → save `logo_saa2025`, `bg_keyvisual`, Google G icon.
2. Run for frame `k-7zJk2B7s` → save `not_found_illustration` (shared asset).
3. Verify @1x/@2x/@3x naming in `Assets.xcassets`.
4. Add 12 localisation keys (VN + EN) to `Localizable.xcstrings`. EN copy uses placeholder text — Q2 answer locks final copy before US3 merges.
```

### Phase 1 — Foundation (PR-M1.1)

Land the security-critical stuff first, **with tests**:

1. Write `KeychainSessionStorageTests` covering: round-trip read/write, delete, behaviour when item missing, `.AfterFirstUnlockThisDeviceOnly` verified via `SecItemCopyMatching` introspection.
2. Implement `KeychainSessionStorage`.
3. Write `AuthRepository` protocol; write `ObserveSessionUseCaseTests` against an `AuthRepositoryStub`.
4. Implement `ObserveSessionUseCase` + a minimal `AuthRepositoryImpl` that returns `.signedOut` always.
5. Wire DI in `Container`; run M0 smoke — must still pass.

### Phase 2 — Core MVP (PR-M1.2, US1)

1. RxTest scenarios for `LoginViewModelTests`:
   - `signInTapped → isLoading = true → navigateHome` (allowlisted)
   - `signInTapped → cancelled → isLoading = false, no error`
   - `signInTapped → network error → errorMessage emits, isLoading = false`
2. Implement `SupabaseAuthDataSource.signInWithOAuth` bridging `async` → `Single.create`.
3. Implement `LoginViewModel` until tests go green.
4. Build `LoginView` consuming `LoginStateAdapter`.
5. XCUITest: launch app → tap CTA → assert OAuth sheet appears (mock provider URL via launch arg).
6. Wire `AppRouter` to switch `RootView` on `AuthStore` events.

### Phase 3 — Disallowed-domain branch (PR-M1.3, US2)

1. RxTest: `oauthCallback → CheckEmailDomainUseCase rejects → SignOutUseCase → navigateAccessDenied`.
2. Implement `CheckEmailDomainUseCase` + `SignOutUseCase`.
3. Build `ErrorStateView` (shared) + `AccessDeniedView` consuming it.
4. XCUITest with staging build (`ALLOWED_EMAIL_DOMAINS=sun-asterisk.com`) signing in with `@gmail.com` test user.
5. **Security gate**: integration test SEC_02 — after disallowed-domain navigation, `KeychainSessionStorage.read()` returns nil.

### Phase 4 — Localisation (PR-M1.4, US3)

1. RxTest: language tap → `presentLanguageSheet` signal → row-tap → `LocaleStore` write → re-render trigger.
2. Build `LanguagePickerSheet`; integrate `LanguageSwitcherChip` into `LoginView` header.
3. AS5 idempotent check: tap current language row → sheet dismisses, `LocaleStore.set` called once but no `.next` emission to subscribers.
4. Snapshot tests rendering `LoginView` + `AccessDeniedView` in both locales.
5. **Q2 unblock gate**: confirm final EN/VN copy with design before merge.

### Phase 5 — Polish + lifecycle + Not Found (PR-M1.5, US4)

1. Bind app foreground notifications to `RestoreSessionUseCase`.
2. RxTest: lifecycle scenarios US4 AS1–AS3.
3. Build `NotFoundView` (consumes shared `ErrorStateView`); register `.notFound(source:)` route.
4. Reduce-Motion audit: any animation gated on `UIAccessibility.isReduceMotionEnabled`.
5. Accessibility pass: VoiceOver walkthrough script (focus order, labels, hints, AX5 size).
6. Analytics events emitted (no PII): `login.viewed`, `login.google_tapped`, `login.success`, `login.denied{email_domain}`, `login.error{code}`.
7. Security review checklist on the PR description (`Security review:` checkbox per Constitution §Workflow).

### Risk Assessment

| Risk | Probability | Impact | Mitigation |
|---|---|---|---|
| Apple Sign-In demand at App Store review (Q1) forces second provider mid-M1 | Med | High | `AuthRepository` already abstracts the provider; if Q1 = yes, add an `AppleSignInDataSource` in PR-M1.6 — does not block M1 ship to TestFlight |
| `ASWebAuthenticationSession` callback URL not registered correctly → OAuth never returns | Med | High | Smoke-test in Phase 2 gating PR-M1.2 merge; M0_README step 3 already covers URL Types |
| Keychain race after `signOut()` (US2 §AS1) leaves stale token | Low | High | Make `signOut()` synchronous-on-Keychain (`signOutFromAuth → deleteFromKeychain → return`); SEC_02 test asserts |
| PKCE `code_verifier` lost on app kill mid-OAuth → silent failure on relaunch | Low | Med | `oauthCallback` filter discards stray URLs (spec edge case); OSLog warning logged |
| Supabase Auth provider misconfigured (Google client ID/secret) | Med | High | Configure on Day 1 of M1; tech lead owns; staging-first |
| Localisation keys diverge between EN/VN string-files vs. catalog | Low | Med | Use `.xcstrings` (single file); CI lint via `swiftlint` custom rule on missing keys |

### Estimated Complexity

| Layer | Complexity |
|---|---|
| **Domain** | Low — small set of use cases, all pure |
| **Data** | Medium — Keychain + async-to-Rx bridging + OAuth callback wiring |
| **Presentation** | Medium — six new shared components, two ViewModels, lifecycle |
| **Testing** | Medium — first feature requires test harness (RxTest scaffolding, XCUITest config) |

Total: ~5–7 working days for one engineer following the PR sequence.

---

## Integration Testing Strategy

### Test scope

- **Component/Module interactions**: `AuthStore` ↔ `AppRouter`; `LoginViewModel` ↔ `AuthRepository`; `KeychainSessionStorage` ↔ `AuthRepositoryImpl`.
- **External dependencies**: `supabase-swift` Auth (provider = Google); `ASWebAuthenticationSession` (mocked in XCUITest via launch args).
- **Data layer**: Keychain (real, scoped to test access group); no Postgres in M1.
- **User workflows**: US1 sign-in → Home; US2 disallowed → Access denied → Login; US3 language switch persists; US4 background → restore.

### Test categories

| Category | Applicable | Key scenarios |
|---|---|---|
| View ↔ ViewModel (Rx → SwiftUI) | Yes | Loading/error/success bindings on `LoginView`; selection highlight on `LanguagePickerSheet` |
| UseCase ↔ Repository | Yes | `SignInWithGoogleUseCase` calls `AuthRepository.signInWithGoogle` → `exchangeCallback`; `CheckEmailDomainUseCase` rejects + triggers `SignOutUseCase` |
| Repository ↔ Supabase | Yes | `SupabaseAuthDataSource` happy + cancel + 5xx + invalid_grant; `signOut()` clears Keychain |
| Auth flow (Supabase Auth ↔ Keychain) | Yes | Sign-in writes session; refresh updates session; sign-out deletes; pre-first-unlock returns `.signedOut` |
| RLS policy enforcement | **No (M1)** | Deferred to M2/M3 once `profiles` is read |
| Accessibility (VoiceOver + Dynamic Type) | Yes | All Login + Access denied + Not Found at AX5; VoiceOver order asserted in XCUITest |

### Test environment

- **Type**: iPhone 15 simulator (Xcode 15+); CI uses macOS-14 runner.
- **Test data**: two seeded test users in Supabase **staging** project — `qa-allowed@sun-asterisk.com`, `qa-blocked@gmail.com` (test domain whitelisted only in staging xcconfig).
- **Isolation**: Keychain tests use a per-test access group; XCUITest launches with a clean simulator state via `xcrun simctl erase`.

### Mocking strategy

| Dependency | Strategy | Rationale |
|---|---|---|
| `supabase-swift` Auth | Real (staging) for integration; **mocked** at `AuthRepository` protocol for ViewModel unit tests | Tests stay fast & deterministic; staging integration runs only in CI gate |
| `ASWebAuthenticationSession` | Real for happy path; launch-argument mock in XCUITest US1 happy path to skip browser flow | Browser automation in CI is brittle; deterministic mock acceptable |
| `Keychain` | Real (with isolated access group) | Mocking Keychain hides the security-critical bug class we care about |
| `OAuth callback URL` | Synthetic deep-link in XCUITest | Reproducible without browser |

### Test scenarios outline

1. **Happy path**
   - [ ] US1: `@sun-asterisk.com` user signs in → `AuthStore.state == .signedIn` → router shows Home placeholder.
   - [ ] US3: language toggle persists across cold launch.
   - [ ] US4: background ≥ access-token TTL → return → no Login flash.
2. **Error handling**
   - [ ] User cancels OAuth sheet → no error toast, button re-enabled.
   - [ ] Network down → localised alert, button re-enabled.
   - [ ] Supabase 5xx on `signInWithOAuth` → alert, no partial Keychain write.
3. **Edge cases**
   - [ ] App killed mid-OAuth → relaunch with stray callback URL → discarded with OSLog warning, user on Login.
   - [ ] Pre-first-unlock launch → `AuthState == .signedOut`; on subsequent foreground after unlock → state re-evaluates.
   - [ ] SEC_02: After disallowed-domain navigation, `KeychainSessionStorage.read() == nil` (asserted).
   - [ ] Tap current language row → sheet dismisses, no re-render churn.

### Tooling & framework

- **Test framework**: XCTest (unit), RxTest/RxBlocking (Rx), XCUITest (UI).
- **CI integration**: existing `.github/workflows/ci.yml` runs all three jobs on every PR.
- **Coverage**: enforce no regression on Domain layer (`xccov` baseline check).

### Coverage goals

| Area | Target | Priority |
|---|---|---|
| Domain use cases | 95%+ | High |
| ViewModels (Rx) | 90%+ | High |
| Data repositories | 80%+ | High |
| Shared SwiftUI components | 70%+ (snapshot) | Medium |
| XCUITest critical paths | US1 + US2 happy paths | High |

---

## Dependencies & Prerequisites

### Required before start

- [x] Constitution v1.0.1 reviewed.
- [x] Spec reviewed (round 2 — 2026-04-25).
- [x] M0 merged (scaffold, SPM, xcconfig wired).
- [ ] Google OAuth client configured in Supabase **staging** project → Auth → Providers → Google. Needs iOS bundle ID's URL scheme (`aidd-saa-2025://auth-callback`).
- [ ] Two seeded test users exist in staging (`qa-allowed@sun-asterisk.com`, `qa-blocked@gmail.com`).
- [ ] Q2 (Access denied copy) answered before PR-M1.4.

### Open Questions (forwarded from spec.md)

- **Q1** (Apple Sign-In) — does NOT block M1 start; if YES, opens follow-up PR-M1.6.
- **Q2** (`accessDenied.title` + `.primaryButton` final copy) — gates PR-M1.4 merge.
- **Q3** (deep-link queue policy) — owned by router feature; M1 implements no queue, just discards stray callback URLs.
- **Q4** (chip placement on Home) — does NOT affect M1; Home is a placeholder until M2.
- **Q5** (production allowlist) — final list goes into `Config/Prod.xcconfig` before TestFlight; staging proceeds with `["sun-asterisk.com", "gmail.com"]` for QA.

### External dependencies

- Supabase staging project (existing).
- `not_found_illustration` asset (Phase 0 deliverable).

---

## Definition of Done (M1)

Per Constitution §Workflow:

- [ ] All US1–US4 acceptance scenarios green on simulator.
- [ ] XCUITest US1 happy path + US2 disallowed-domain green in CI.
- [ ] VoiceOver pass at AX5 on all three screens.
- [ ] No new SwiftLint warnings; no `TODO` without an issue link.
- [ ] No service-role key in bundle (CI secret-scan green).
- [ ] SEC_02 passes (no residual token after disallowed sign-out).
- [ ] PR descriptions include "Constitution check" + "Security review" lines.
- [ ] `Package.resolved` unchanged from M0 (no surprise dep additions).
- [ ] M1 exit criteria from roadmap met: `@sun-asterisk.com` → Home placeholder; `@gmail.com` (non-prod) → Access denied → Login.

---

## Next Steps

1. Run `/momorph.tasks` to break this plan into discrete, ordered, parallelisable tasks.
2. Open the 5 PRs sequenced above (PR-M1.0 → PR-M1.5).
3. Resolve Q1 (Apple Sign-In) in parallel — answer can land in PR-M1.6 without delaying M1 ship.

---

## Notes

- M1 carries the cost of introducing the testing harness (RxTest scheduler patterns, XCUITest launch-arg conventions, Keychain access-group setup). Subsequent milestones inherit this for free — keep PR-M1.1 review thorough.
- The `LanguagePickerSheet` lives in `Presentation/Shared/Components/` despite first appearing on Login — Home (M2) and ProfileMe (M3) will both consume it.
- `RootView` replaces the M0 placeholder `ContentView`. The smoke screen ("Bootstrap OK + Supabase URL") is removed — the new app launch shows splash → Login (or Home if cached session).
