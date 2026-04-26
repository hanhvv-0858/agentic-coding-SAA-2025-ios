# Feature Specification: Authentication

**Frame IDs**: `8HGlvYGJWq` (Login — primary), `k-7zJk2B7s` (Access denied)
**Frame Names**: `[iOS] Login`, `[iOS] Access denied`
**File Key**: `9ypp4enmFmdK3YAFJLIu6C`
**Related screen specs**: [login.md](../../contexts/screen_specs/login.md), [access-denied.md](../../contexts/screen_specs/access-denied.md)
**Created**: 2026-04-25
**Status**: Reviewed (2026-04-25 — pending answers to Open Questions)

---

## Overview

This feature gates all access to the Sun\* SAA 2025 iOS app. It covers the
unauthenticated stack — **Google SSO sign-in**, **client-side email-domain
allowlist**, **language switching**, and the **Access denied** terminal
state — and provides the auth boundary used by every other feature.

**Target users**: Sunners (employees of Sun\* and approved partner
domains). The default allowlist is `sun-asterisk.com`; non-production
builds may add `gmail.com` for QA. See [login.md](../../contexts/screen_specs/login.md)
for the canonical decision.

**Business context**: this is the first surface a user touches. Trust,
speed, and correctness here set the tone for the entire product. The
allowlist is a **navigation gate** — the **security boundary** is
Supabase RLS on every accessible table (constitution Principle V).
Widening the allowlist therefore does NOT widen data exposure.

---

## User Scenarios & Testing *(mandatory)*

### User Story 1 — Sign in with Google (Priority: P1) 🎯 MVP

A Sunner opens the app, sees the Login screen, taps "LOGIN With Google",
completes the Google OAuth flow, and lands on the SAA tab (Home). On
subsequent cold launches their session is restored automatically — they
do NOT have to sign in again.

**Why this priority**: this is THE MVP. Without it, no other feature is
reachable.

**Independent Test**: a `@sun-asterisk.com` test user signs in once →
lands on Home. Force-quit app → relaunch → lands on Home directly without
seeing Login.

**Acceptance Scenarios**:

1. **Given** the user is on Login (no session in Keychain), **When**
   they tap "LOGIN With Google" and complete Google OAuth in the
   `ASWebAuthenticationSession`, **Then** the app exchanges the code
   for a Supabase session, persists it to Keychain with
   `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`, and navigates to
   `[iOS] Home` (replacing the navigation root).
2. **Given** the user is on Login, **When** they tap "LOGIN With
   Google" but cancel the OAuth web sheet, **Then** no session is
   created, the user remains on Login, and no error toast is shown
   (silent dismissal).
3. **Given** there is a valid Supabase session in Keychain, **When**
   the app cold-launches, **Then** the user lands directly on Home (no
   Login flash).
4. **Given** there is a session in Keychain whose refresh has expired,
   **When** the app cold-launches, **Then** the SDK detects the
   expiry, the session is purged, and the user lands on Login.
5. **Given** the user is on Login, **When** there is no network,
   **Then** the OAuth tap surfaces a clear localised alert
   `"Không có kết nối mạng. Thử lại."` / `"No connection. Try again."`,
   the button stays enabled, and the user can retry.

---

### User Story 2 — Recover from disallowed domain (Priority: P1)

A user who signs in with a Google account whose email domain is NOT in
the configured allowlist is shown the Access denied screen, signed out
of Supabase, and offered a way back to Login to try a different
account.

**Why this priority**: blocks unauthorised access AND ensures the user
isn't trapped in an inconsistent state with a half-valid session.

**Independent Test**: in the staging build configured with allowlist
`["sun-asterisk.com"]` only, sign in with a `@gmail.com` Google
account → Access denied screen renders → tap "Go back to Home" → Login
re-renders with no residual session.

**Acceptance Scenarios**:

1. **Given** the user has just completed Google OAuth with email
   `alice@gmail.com` and the configured allowlist is
   `["sun-asterisk.com"]`, **When** the app evaluates the email
   domain, **Then** it MUST call `supabase.auth.signOut()` BEFORE
   navigating, and the navigation MUST land on `[iOS] Access denied`.
   Keychain MUST contain no session token after the navigation
   completes.
2. **Given** the user is on Access denied, **When** they tap the
   "Go back to Home" button OR the Back icon in the top navigation,
   **Then** the navigation stack resets and the user lands on
   `[iOS] Login` (NOT on Home — they are unauthenticated).
3. **Given** the user is on Access denied, **When** they re-sign in
   on Login with an allowlisted account, **Then** the previous Access
   denied state is fully discarded (no breadcrumb back to it) and the
   user lands on Home.
4. **Given** the OAuth response unexpectedly contains no email claim,
   **When** the domain check runs, **Then** the user is treated as
   disallowed (sign out + Access denied) and a warning is logged
   server-side via OSLog (never including the actual user_id or token).

---

### User Story 3 — Switch interface language (Priority: P2)

A Sunner taps the language chip in the header, picks `Tiếng Việt` or
`Tiếng Anh` from the dropdown, and the entire app re-renders in the
chosen language. Their choice persists across launches.

**Why this priority**: the SAA programme is bilingual; many Sunners
prefer English. v1 ships VN + EN.

**Independent Test**: open the app on a fresh install (system language
= EN). The Login screen renders in EN. Tap the chip → pick `Tiếng
Việt` → Login re-renders in VN. Force-quit and relaunch → Login still
in VN.

**Acceptance Scenarios**:

1. **Given** the user is on Login OR Home (both expose the chip),
   **When** they tap the language chip, **Then** the LanguagePickerDropdown
   is presented as an anchored dropdown card below the chip (matching
   Figma `[iOS] Language dropdown`) showing exactly 2 rows
   (`Tiếng Việt`, `Tiếng Anh`) with the current selection highlighted.
2. **Given** the LanguagePickerDropdown is open, **When** the user picks
   the alternative language, **Then** the dropdown dismisses, the choice
   is persisted to `LocaleStore` (which writes to `UserDefaults` —
   non-sensitive), and every visible text element re-renders in the
   selected language within 250 ms.
3. **Given** the user has never explicitly picked a language, **When**
   they first open the app, **Then** the default is the device locale
   if it is `vi` or `en`; otherwise default to `en`.
4. **Given** the user picks a language, **When** they cold-launch the
   app, **Then** the chosen language is restored before any UI
   renders.
5. **Given** the LanguagePickerDropdown is open with the current
   language already highlighted, **When** the user taps the
   *currently selected* row, **Then** the dropdown dismisses without
   re-writing `LocaleStore` (idempotent set) and no re-render is
   triggered.

---

### User Story 4 — Auto-resume session on tab switch / background return (Priority: P2)

A signed-in user puts the app in the background, returns later, and the
app restores the session and current tab without showing Login.

**Why this priority**: lifecycle robustness; expected behaviour for
modern iOS apps.

**Independent Test**: sign in → switch to another app for 5 minutes →
return → app shows Home (or whatever tab was active) immediately.

**Acceptance Scenarios**:

1. **Given** the app is foregrounded with a valid session, **When**
   the user backgrounds the app and returns within the access-token
   TTL, **Then** the same UI state is restored without re-fetching
   the session.
2. **Given** the access token has expired in the background, **When**
   the user returns, **Then** the SDK silently refreshes via the
   refresh token before any UI fetch fires; the user observes no
   Login flash.
3. **Given** both tokens have expired (long absence), **When** the
   user returns, **Then** the app routes to Login. Pending deep links
   (if any) are queued and replayed after the next successful sign-in.
   **Out of scope for this feature**: the deep-link queue policy
   (queue size, TTL, supported URL schemes vs. universal links) is
   defined by the navigation/router feature and is referenced — not
   designed — here.

---

### Edge Cases

- **Concurrent sign-in attempts**: rapid double-taps on "LOGIN With
  Google" must not start two OAuth sessions; debounce taps by 300 ms
  AND disable the button while `.isLoading == true`.
- **Empty / unstable network**: OAuth callback may arrive after a
  network blip; the URL handler MUST be idempotent (calling
  `exchangeCodeForSession` twice with the same code returns the same
  result or a clean `invalid_grant` error).
- **App killed mid-OAuth (PKCE verifier loss)**: if the app is
  terminated between `signInWithOAuth` and the callback URL handler,
  the in-memory PKCE `code_verifier` is lost. On relaunch, the
  callback URL MUST be discarded (with an OSLog warning) and the user
  shown the Login screen. The Supabase SDK is responsible for
  persisting/managing the verifier; if the SDK chooses to write it to
  disk, that storage MUST be Keychain (never `UserDefaults`).
- **Keychain locked (pre-first-unlock)**: with
  `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`, the cached
  session is unreadable before the device's first unlock after boot.
  In that window the app MUST treat the state as `signedOut` and show
  Login; on next foreground after unlock, the cached session is
  re-checked (no automatic re-prompt for the user).
- **Token contains email but domain has unicode** (e.g.
  `user@bücker.de`): normalise via NFC + lowercase before comparing
  against the allowlist; v1 allowlist contains only ASCII domains so
  this is a forward-compat measure.
- **Background sign-out from another device**: detected on next
  `auth.getSession()` returning null; route to Login without an
  alert.
- **Stray callback URLs**: the `oauthCallback: PublishRelay<URL>`
  MUST filter incoming URLs by scheme + host; URLs that do not match
  the configured `OAUTH_REDIRECT_URL` (e.g. unrelated deep links)
  are forwarded to `AppRouter` instead of being passed to
  `exchangeCodeForSession`.
- **Supabase service unavailable (5xx) on `signInWithOAuth`**:
  surfaces a localised alert (`auth.error.network`-class message)
  and the CTA returns to `idle`. No partial session is ever
  written to Keychain.
- **Anonymous variant**: not applicable — this feature has no
  anonymous mode (every user must be a real Google account).

---

## UI/UX Requirements *(from Figma)*

### Screen Components

#### Login (`8HGlvYGJWq`)

| Component | Description | Interactions |
|-----------|-------------|--------------|
| `BackgroundImage` (atom) | Full-bleed key-visual; no interaction | — |
| `BrandLogoSmall` (atom) | Header logo | — |
| `LanguageSwitcherChip` (molecule) | Header chip showing flag + language code + chevron | Tap → present `LanguagePickerDropdown` |
| `HeroLogo` (atom) | Center brand mark | — |
| `WelcomeText` (atom, localised) | Two-line welcome copy | — |
| `GoogleSignInButton` (molecule, primary CTA) | "LOGIN With Google" + Google icon | Tap → start OAuth flow (US1 / US2) |
| `Footer` (atom) | Copyright text | — |

#### Access denied (`k-7zJk2B7s`)

| Component | Description | Interactions |
|-----------|-------------|--------------|
| `TopNavigation` (organism, shared) | Status bar + back icon (no title) | Back tap → pop to Login |
| `BackgroundImage` (atom) | Full-bleed key-visual | — |
| `ErrorStateView` (organism, shared with Not Found) | Title + divider + subtitle + illustration + primary button | — |
| `PrimaryButton` "Go back to Home" | Navigates back to Login (despite the label) | Tap → reset stack to Login |

### Navigation Flow

- **From**: app launch (no valid session) OR successful sign-out OR
  expired session detection.
- **To**: `[iOS] Home` on success (US1), `[iOS] Access denied` on
  disallowed domain (US2).
- **Sub-sheet**: `[iOS] Language dropdown` (`uUvW6Qm1ve`) — folded into
  this feature's `LanguagePickerDropdown` component.

### Behavioral Requirements (iOS / HIG — Principle II)

- **Device support**: iPhone portrait is primary. iPad and landscape MUST
  remain functional (no clipping, no broken layout); concrete responsive
  breakpoints are an implementation concern.
- **Appearance**: Light + Dark Mode both supported via semantic colors.
- **Dynamic Type**: Login welcome copy + button label + AccessDenied
  title/subtitle/button MUST scale to AX5 without truncation. Hero logo
  retains its intrinsic size.
- **Motion**: any non-essential animation MUST be disabled when
  `UIAccessibility.isReduceMotionEnabled == true`. The OAuth web sheet
  uses the system transition (no override).
- **Accessibility (MANDATORY)**:
  - `accessibilityLabel("Đăng nhập bằng Google")` on the CTA.
  - `accessibilityLabel("Ngôn ngữ hiện tại: ..., nhấn để đổi")` on the chip.
  - All tap targets MUST meet the HIG minimum touch-target size.
  - VoiceOver order: chip → hero → CTA → footer (Login); back → title
    → subtitle → CTA (Access denied).
- **Localisation**: every user-facing string MUST be a key in
  `Localizable.xcstrings`. v1 keys: `login.welcome.title`,
  `login.welcome.subtitle`, `login.cta`, `login.langChip.hint`,
  `accessDenied.title`, `accessDenied.subtitle`, `accessDenied.primaryButton`,
  `lang.vi`, `lang.en`, `auth.error.network`,
  `auth.error.cancelled.silent` (no UI), `auth.error.disallowedDomain`.
  Suggested EN copy: see [access-denied.md](../../contexts/screen_specs/access-denied.md)
  *(VN: "Quay lại đăng nhập"; EN: "Back to sign in")*.

---

## Component Behavior

(Each interactive component lists its Node ID — use these in
`get_node` / `query_section` during implementation.)

### Login screen — `[iOS] Login` (`8HGlvYGJWq`)

| Component | Node ID | Behaviour |
|-----------|---------|-----------|
| `LanguageSwitcherChip` | `6885:8976` | **Interaction**: Tap. **Effect**: presents `LanguagePickerDropdown` (US3). **Validation**: none. **State**: enabled always (does not depend on auth state). **Accessibility**: announces current language; trait `.isButton`; chip wrapped in a HIG-minimum tap area. |
| `GoogleSignInButton` | `6885:8969` | **Interaction**: Tap. **Effect**: dispatches `signInTapped` on `LoginViewModel` (US1, US2). **State transitions**: `idle → loading` while OAuth sheet is presented; `loading → idle` on success/cancel/error. **Disabled** when `isLoading == true`. **Validation**: none. **Accessibility**: trait `.isButton`; replaces leading icon with `ProgressView` while loading. |

### Access denied screen — `[iOS] Access denied` (`k-7zJk2B7s`)

| Component | Node ID | Behaviour |
|-----------|---------|-----------|
| `BackIconButton` (in `TopNavigation`) | `6885:9509` | **Interaction**: Tap. **Effect**: emits the same `navigateLogin` signal as the primary button. **State**: always enabled. |
| `PrimaryButton` "Go back to Home" | `6885:9531` | **Interaction**: Tap. **Effect**: routes to `[iOS] Login` (NOT Home — user is unauthenticated; the label is a known UX mismatch flagged for design re-copy). **Validation**: none. **Accessibility**: trait `.isButton`; hint announces the real destination ("Quay lại màn đăng nhập" / "Returns to sign-in"). |

### LanguagePickerDropdown (folded from `[iOS] Language dropdown` `uUvW6Qm1ve`)

| Component | Node ID | Behaviour |
|-----------|---------|-----------|
| `LanguagePickerDropdown` (new molecule) | n/a (frame-level) | **Interaction**: presented from `LanguageSwitcherChip` tap. **Effect**: 2 rows — `Tiếng Việt`, `Tiếng Anh` — tapping a row sets `LocaleStore.appLanguage` and dismisses. **State**: highlights the currently selected row. **Persistence**: `UserDefaults` key `appLanguage`. **Accessibility**: each row is a separate `.isButton` element; selected row adds `.isSelected`. |

---

## Data Requirements

### Inputs (none typed by the user)

This feature has zero user-typed input — all credentials flow through
Google OAuth.

### Display fields (per screen)

| Field | Source | Type | Notes |
|-------|--------|------|-------|
| `currentLanguage` | `LocaleStore` (UserDefaults) | `AppLanguage` enum (`.vi`, `.en`) | Drives the chip flag + label |
| Welcome title / subtitle | `Localizable.xcstrings` | `String` | Bound to `currentLanguage` |
| CTA label | `Localizable.xcstrings` | `String` | "LOGIN With Google" stays as-is per design (brand requirement) |
| Footer | `Localizable.xcstrings` | `String` | "Bản quyền thuộc về Sun\* © 2025" |
| Access denied title / subtitle | `Localizable.xcstrings` | `String` | See Open Question Q2 — title localisation pending design decision |
| Access denied illustration | `Asset Catalog` | image asset `not_found_illustration` (shared with Not Found) | — |

### Domain entities introduced

```swift
enum AppLanguage: String, Codable, CaseIterable {
    case vi      // Tiếng Việt
    case en      // English
}

struct AllowedEmailDomains: Equatable {
    let domains: Set<String>     // e.g. ["sun-asterisk.com"]
    func allows(emailDomain: String) -> Bool
}

struct AuthSession: Equatable {
    let accessToken: String
    let refreshToken: String
    let expiresAt: Date
    let user: AuthUser
}

struct AuthUser: Equatable {
    let id: UUID
    let email: String
    /// Computed deterministically as: substring after the *last* `@`,
    /// trimmed of whitespace, NFC-normalised, lowercased.
    /// Used by `CheckEmailDomainUseCase`; never logged.
    let emailDomain: String
}
```

### Storage requirements

| Store | Backing | Lifetime | Reason |
|-------|---------|----------|--------|
| Session tokens | iOS Keychain (`kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`) | persist across launches | Principle V — never `UserDefaults` for tokens |
| `appLanguage` | `UserDefaults` | persist across launches | non-sensitive |
| `allowedEmailDomains` | `Info.plist` injected from `Config/*.xcconfig` | bundled at compile | constitution-controlled config |

---

## API Requirements (Predicted)

All endpoint shapes are formalised in
[api-docs.yaml](../../contexts/api-docs.yaml).

| Endpoint / SDK call | Method | Purpose | Triggered by |
|---------------------|--------|---------|--------------|
| `supabase.auth.signInWithOAuth(provider:.google, redirectTo:)` | POST `/auth/v1/authorize?provider=google` | Start Google OAuth | US1: tap CTA |
| `ASWebAuthenticationSession` | OS | Open OAuth web flow | After SDK returns `url` |
| `supabase.auth.exchangeCodeForSession(code)` | POST `/auth/v1/token?grant_type=pkce` | Exchange OAuth code for tokens | US1: OAuth callback URL handler |
| `supabase.auth.getSession()` | local (cached) | Restore session on cold launch | US1, US4: app appear |
| `supabase.auth.refreshSession()` | POST `/auth/v1/token?grant_type=refresh_token` | Background refresh near expiry | SDK auto + US4 |
| `supabase.auth.signOut()` | POST `/auth/v1/logout` | Clear session | US2: domain mismatch • Profile (out of scope) |

**Allowlist check**: NO API call. Resolved client-side in
`CheckEmailDomainUseCase` against the bundled `ALLOWED_EMAIL_DOMAINS`
config.

---

## State Management

### Local — `LoginViewModel` (Principle III)

```swift
protocol LoginViewModel {
    // Inputs
    var signInTapped: PublishRelay<Void> { get }
    var languageTapped: PublishRelay<Void> { get }
    var oauthCallback: PublishRelay<URL> { get }     // wired from app delegate

    // Outputs
    var isLoading: Driver<Bool> { get }
    var selectedLanguage: Driver<AppLanguage> { get }
    var errorMessage: Signal<String> { get }         // for transient alerts
    var navigateHome: Signal<Void> { get }
    var navigateAccessDenied: Signal<Void> { get }
    var presentLanguageSheet: Signal<Void> { get }
}
```

Outputs MUST use `Driver` / `Signal` (no `.error`); errors are
materialised into the `errorMessage` channel.

### Local — `AccessDeniedViewModel`

```swift
protocol AccessDeniedViewModel {
    var primaryTapped: PublishRelay<Void> { get }
    var backTapped: PublishRelay<Void> { get }
    var navigateLogin: Signal<Void> { get }
}
```

Backed by a single merged `Signal<Void>`; no async work, no loading
state.

### Global

| Store | Owns | Producers | Consumers |
|-------|------|-----------|-----------|
| `AuthStore` | `AuthState` (`.unknown` / `.signedOut` / `.signedIn(AuthSession)`) | `AuthRepository.observe()` Rx stream | `AppRouter` (decides root), every authenticated screen (gating reads) |
| `LocaleStore` | `currentLanguage: AppLanguage` | `LanguagePickerDropdown` selection | All Views consuming `Localizable.xcstrings` |
| `AppRouter` | Top-level navigation root (`.login` / `.home` / `.accessDenied`) | `AuthStore` events | Root SwiftUI view |

### Cache / invalidation

- Session tokens: cached by Supabase SDK; refresh transparently. App
  must NOT add its own caching layer.
- `currentLanguage`: cached in `UserDefaults`; invalidated only by
  user action.
- `allowedEmailDomains`: bundled at compile; no runtime invalidation.

### Optimistic updates

- **None**. The session-related screens are guard surfaces; they wait
  for confirmation from the SDK before transitioning.

---

## Constitution alignment

Cross-checked against [.momorph/constitution.md](../../constitution.md) v1.0.1:

- **I. Clean Architecture**: ✅ — clear `Presentation/Domain/Data/Core`
  split; Domain has no Supabase imports; ViewModels expose Rx I/O,
  Views consume only `@Published` state via adapter.
- **II. SwiftUI-First & HIG**: ✅ — every screen built in SwiftUI;
  Dynamic Type AX5; semantic colours for Light/Dark; localisation
  via `Localizable.xcstrings`; HIG-minimum touch targets enforced;
  VoiceOver walkthrough mandated as a P1 acceptance test.
- **III. Reactive Data Flow with RxSwift**: ✅ — auth observation,
  OAuth callback handling, language change all flow through
  `Observable`/`Single`/`Signal`; `DisposeBag` per ViewModel; explicit
  schedulers at SDK boundaries.
- **IV. Test-First Discipline**: ✅ — RxTest scenarios covering
  US1–US4 acceptance criteria are required before the corresponding
  ViewModel implementation lands. XCUITest covering US1 happy path is
  a merge gate.
- **V. Secure-by-Default**: ✅ — Keychain accessibility class strictly
  set; no service-role key in bundle; logs use `.private`; allowlist
  documented as a navigation gate (RLS is the security boundary on
  every accessed table); ATS exceptions = none.

---

## Success Criteria *(mandatory)*

| ID | Metric | Target |
|----|--------|--------|
| SC-AUTH-1 | Time-to-first-screen on cold launch with cached session | < 800 ms (p95) |
| SC-AUTH-2 | OAuth round-trip from CTA tap to Home navigation | < 4 s (p95) on a stable network |
| SC-AUTH-3 | Session restoration success rate after backgrounding (within token TTL) | ≥ 99.5 % |
| SC-AUTH-4 | Sign-out completeness (no residual token in Keychain) | 100 % verified by automated test SEC_02 |
| SC-AUTH-5 | Anonymity boundary: 0 cases of leaked sender_id observed across SEC_01 audit | 100 % (covered in BACKEND_API_TESTCASES → FEED_03–FEED_07) |
| SC-AUTH-6 | Crash-free sessions on Login + Access denied | ≥ 99.9 % |

---

## Out of Scope

- Email/password sign-in.
- Phone OTP.
- Apple Sign-In.
- Avatar / profile editor (handled in M3 — Profile cluster).
- In-app password recovery (Google handles it).
- Multi-account switching.
- Biometric re-authentication for sensitive actions (deferred to v-next
  per [login.md](../../contexts/screen_specs/login.md) backlog).

---

## Dependencies

- [x] Constitution document exists ([.momorph/constitution.md](../../constitution.md))
- [x] Database schema applied (migrations 0022–0028 covered in [database-schema.sql](../../contexts/database-schema.sql))
- [x] API contract defined ([api-docs.yaml](../../contexts/api-docs.yaml))
- [x] Screen specs ratified ([login.md](../../contexts/screen_specs/login.md), [access-denied.md](../../contexts/screen_specs/access-denied.md))
- [ ] Google OAuth app configured in Supabase Auth → Providers → Google
      with the iOS bundle's URL scheme (`<scheme>://auth-callback`)
- [ ] `Config/Dev.xcconfig` + `Config/Staging.xcconfig` +
      `Config/Prod.xcconfig` populated with `SUPABASE_URL`,
      `SUPABASE_ANON_KEY`, `ALLOWED_EMAIL_DOMAINS` (no service-role)
- [ ] Asset `not_found_illustration` exported (shared with Not Found
      feature)

---

## Open Questions (await PM / design / App Store)

| # | Question | Why it matters | Owner |
|---|----------|----------------|-------|
| Q1 | Is **Apple Sign-In** required for v1? App Store §4.8 mandates Apple Sign-In whenever third-party social sign-in is offered. | Decides whether `AuthRepository` ships with a second provider in M1 or only Google. The repo abstraction already accommodates both. | PM + App Store reviewer |
| Q2 | Final copy for the `accessDenied.primaryButton` (current "Go back to Home" is misleading — user is signed out). Proposed: VN `"Quay lại đăng nhập"`, EN `"Back to sign in"`. **Also**: should `accessDenied.title` stay as the English string `"Access Denied"` or be localised to `"Truy cập bị từ chối"` for VN? | Lock localised strings for `Localizable.xcstrings` before M1 implementation. | Design |
| Q3 | Deep-link replay policy referenced in US4 AS3 — what URLs are queueable, what is the TTL, and is queue size capped? | Affects router contract; auth feature only consumes `AppRouter.replayPendingLink()`. Spec is fine without an answer; the router feature spec must define it. | Tech lead |
| Q4 | Do we have to keep the `[iOS] Login` chip on `[iOS] Home` after sign-in (Home spec says yes), or move to a Profile/Settings sheet? | Affects `LocaleStore` consumers and where `LanguagePickerDropdown` is presented from. | PM |
| Q5 | Production allowlist: confirm `["sun-asterisk.com"]` is final and that no partner domains (e.g. `sun-asterisk.com.vn`, contractor accounts) are needed for v1. | Bundled at compile via `Config/Prod.xcconfig`; widening requires an app release. | PM |

## Notes

- The "Go back to Home" label on Access denied is a UX mismatch — the
  user is unauthenticated, so the destination is Login, not Home. This
  is currently handled by the spec & the VoiceOver hint explaining the
  real destination. Open issue with design for v1.1 copy revision.
- The allowlist starts strict (`sun-asterisk.com` only) and can be
  widened via `.xcconfig` per environment without an app update — the
  allowlist itself is bundled, so widening DOES require an app
  release. v-next: consider moving the allowlist to a Supabase
  remote-config row so PM can edit at runtime.
- Apple Sign-In rejection risk: App Store policy now requires Apple
  Sign-In if **any** third-party social sign-in is offered. Confirm
  with App Store before submission. May force adding Apple Sign-In to
  this feature; if so, the AuthRepository abstracts the provider so
  the change is contained.
