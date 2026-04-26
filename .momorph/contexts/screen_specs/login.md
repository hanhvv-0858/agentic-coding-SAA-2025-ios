# Screen: [iOS] Login

## Screen Info

| Property | Value |
|----------|-------|
| **Figma Frame ID** | `8HGlvYGJWq` (node `6885:8963`) |
| **Figma Link** | https://momorph.ai/files/9ypp4enmFmdK3YAFJLIu6C/screens/8HGlvYGJWq |
| **Screen Group** | Authentication |
| **Platform** | iOS (SwiftUI) |
| **Status** | discovered |
| **Discovered At** | 2026-04-24 |
| **Last Updated** | 2026-04-24 |

---

## Description

Entry screen for the **Sun\* SAA 2025** iOS app. It is an unauthenticated gate
that offers **Google Sign-In** as the only auth method. The screen shows the
product logo, a bilingual/localisable welcome line, a single primary CTA
(`LOGIN With Google`), a top-right language switcher (defaulting to `VN`), and
a copyright footer.

On successful Google OAuth the app navigates to `[iOS] Home`. Users whose
email domain is not in the allowlist (default: `sun-asterisk.com`; configurable
to also include `gmail.com`) are routed to `[iOS] Access denied`. Tapping the
language chip opens `[iOS] Language dropdown` (supported locales v1: `VN`,
`EN`).

---

## Navigation Analysis

### Incoming Navigations (From)

| Source | Trigger | Condition |
|--------|---------|-----------|
| App launch | Auto | No valid Supabase session in Keychain |
| Logout (from Profile) | Auto | User taps Logout; session cleared |
| Session expiry | Auto | Supabase refresh token failed |

### Outgoing Navigations (To)

| Target Screen | Trigger Element | Node ID | Confidence | Notes |
|---------------|-----------------|---------|------------|-------|
| `[iOS] Home` (`OuH1BUTYT0`) | Button "LOGIN With Google" → OAuth success + email domain in allowlist | `6885:8969` | High | Primary happy path; allowlist default = `sun-asterisk.com` (extensible to `gmail.com`) |
| `[iOS] Access denied` (`k-7zJk2B7s`) | Button "LOGIN With Google" → OAuth success but email domain NOT in allowlist | `6885:8969` | High | Client signs out immediately before navigating |
| `[iOS] Language dropdown` (`uUvW6Qm1ve`) | Tap on language chip ("VN" + flag + chevron) | `6885:8976` | High | v1 offers `VN` and `EN` only |
| (stays) Login | OAuth cancelled / network error | — | High | Error alert, user stays on Login |

### Navigation Rules

- **Back behavior**: Login is the root of the unauthenticated stack — no back.
- **Deep link support**: No. The app should route any deep link to Login first
  if no session exists, then replay the link after auth.
- **Auth required**: No (this IS the auth entry point).
- **OAuth callback**: Handled via `ASWebAuthenticationSession`; the Supabase
  redirect URI MUST be registered in `Info.plist` under `CFBundleURLTypes`.

---

## Component Schema

### Layout Structure

```
┌─────────────────────────────────────┐
│ StatusBar (time)          (battery) │ ← iOS/Component/StatusBar
├─────────────────────────────────────┤
│  [MM_MEDIA_logo]        [🇻🇳 VN ▾]  │ ← header
│                                      │
│                                      │
│                                      │
│          [RootFuther logo]           │ ← mms_3 (hero logo)
│                                      │
│   Bắt đầu hành trình của bạn         │ ← mms_4 (welcome text,
│      cùng SAA 2025.                  │    two lines, localised)
│   Đăng nhập để khám phá!             │
│                                      │
│   ┌─────────────────────────────┐    │
│   │  [G]  LOGIN With Google     │    │ ← mms_5 (primary CTA)
│   └─────────────────────────────┘    │
│                                      │
│                                      │
├─────────────────────────────────────┤
│     Bản quyền thuộc về Sun* © 2025   │ ← footer
└─────────────────────────────────────┘
```

### Component Hierarchy

```
LoginScreen (SwiftUI View)
├── BackgroundImage (Atom)                        # bg / MM_MEDIA_Keyvisual BG
├── Header (Organism)
│   ├── StatusBar (Atom — provided by iOS)        # iOS/Component/StatusBar
│   ├── BrandLogoSmall (Atom)                     # mms_2_mm_media_logo
│   └── LanguageSwitcherChip (Molecule)           # mms_2.1_language
│       ├── FlagIcon (Atom)                       # IC VN Flag / IC JP Flag
│       ├── LanguageCodeLabel (Atom)              # "VN" / "JP" / "EN"
│       └── ChevronDownIcon (Atom)
├── HeroSection (Organism)
│   ├── HeroLogo (Atom)                           # mms_3_Logo/RootFuther
│   └── WelcomeText (Atom, localised)             # mms_4_content
├── GoogleSignInButton (Molecule — primary CTA)   # mms_5_Button
│   ├── GoogleIcon (Atom)
│   └── ButtonLabel (Atom, localised)
└── Footer (Atom)                                 # mms_6 copyright
```

### Main Components

| Component | Type | Node ID | Description | Reusable |
|-----------|------|---------|-------------|----------|
| `StatusBar` | Atom | `6885:8975` | Provided by iOS — not custom-drawn | N/A |
| `BrandLogoSmall` | Atom | `6885:8977` | Header logo | Yes |
| `LanguageSwitcherChip` | Molecule | `6885:8976` | Tap target opens Language dropdown | Yes (also on Home) |
| `HeroLogo` | Atom | `6885:8967` | Large centre brand mark | No |
| `WelcomeText` | Atom | `6885:8968` | Two-line localised string | No |
| `GoogleSignInButton` | Molecule | `6885:8969` | Primary action | No (auth-specific) |
| `Footer` | Atom | `6885:8971` | Copyright text | Yes |

---

## Form Fields (If Applicable)

Not applicable — this screen has no user-editable fields. Authentication is
delegated to Google via OAuth; the user never types credentials in the app.

---

## API Mapping

Backend: **Supabase** (constitution V — no bespoke auth backend). Google
Sign-In is configured in Supabase Auth → Providers → Google.

### On Screen Load

| API | Method | Purpose | Response Usage |
|-----|--------|---------|----------------|
| Keychain read (`sb-session`) | local | Detect existing session | If a valid session exists, skip Login and go to `[iOS] Home` |
| `supabase.auth.getSession()` | SDK | Validate cached token still refreshes | Same |
| Local bundle read (`Localizable.xcstrings`) | local | Load localised strings for current locale (`VN` or `EN`) | Populates welcome copy and CTA label |

### On User Action

| Action | API / SDK call | Method | Request | Response |
|--------|----------------|--------|---------|----------|
| Tap `LOGIN With Google` | `supabase.auth.signInWithOAuth(provider: .google, redirectTo: <app-scheme>://auth-callback)` | POST to Supabase Auth | `{ provider: "google" }` | OAuth URL — open in `ASWebAuthenticationSession` |
| OAuth callback handled | `supabase.auth.exchangeCodeForSession(code)` | POST `/auth/v1/token?grant_type=pkce` | `{ code, code_verifier }` | `{ access_token, refresh_token, user }` — persisted in Keychain |
| Domain allowlist check | **Client-side, in `CheckEmailDomainUseCase`** — no API call | local | `session.user.email` | If domain ∈ `allowedEmailDomains` → go to Home; else call `signOut()` and go to Access denied |
| Tap language chip | none (local) | — | — | Opens `[iOS] Language dropdown` sheet (v1: VN, EN) |

The allowlist is configured in `Config/*.xcconfig`, injected into the app as
an `Array<String>` via `Info.plist`:

```
ALLOWED_EMAIL_DOMAINS = sun-asterisk.com
# dev/staging may add: sun-asterisk.com gmail.com
```

> **Security note (Principle V)**: the domain check is a *navigation gate*,
> not a security boundary. Any row a user can read after sign-in MUST be
> gated by RLS on the backing table — never rely on the client-side domain
> check to protect data. A user with any Google account can always obtain
> a valid Supabase session; RLS is what keeps their reach bounded.

### Error Handling

| Error | Source | UI action |
|-------|--------|-----------|
| User cancelled OAuth | `ASWebAuthenticationSessionError.canceledLogin` | Silent — stay on Login |
| Network failure | URLError | Alert: "Không có kết nối mạng. Thử lại." / "No connection. Try again." + button stays active |
| OAuth provider error | Supabase error | Alert with message from `AuthError.localizedDescription` |
| Email domain not in allowlist | `CheckEmailDomainUseCase` | `signOut()`, then navigate to `[iOS] Access denied` (no stale token left in Keychain) |
| Session without email claim | Edge case | Treat as denied; sign out + navigate to Access denied |
| Supabase service down (5xx) | REST | Alert with retry |

---

## State Management

### Local State (ViewModel — Principle III)

```swift
protocol LoginViewModel {
    // Inputs
    var signInTapped: PublishRelay<Void> { get }
    var languageTapped: PublishRelay<Void> { get }
    var oauthCallback: PublishRelay<URL> { get }

    // Outputs
    var isLoading: Driver<Bool> { get }
    var selectedLanguage: Driver<AppLanguage> { get }    // v1: "VN" / "EN"
    var errorMessage: Signal<String> { get }
    var navigateHome: Signal<Void> { get }
    var navigateAccessDenied: Signal<Void> { get }
    var presentLanguageSheet: Signal<Void> { get }
}
```

| State | Type | Initial | Purpose |
|-------|------|---------|---------|
| `isLoading` | `Bool` | `false` | Disable button + show spinner during OAuth |
| `selectedLanguage` | `AppLanguage` | persisted or device locale | Drives flag + label + copy |
| `errorMessage` | `String?` | `nil` | Transient alert |

### Global State

| State | Store | R/W | Purpose |
|-------|-------|-----|---------|
| `AuthState` | `AuthStore` (Domain) | Write | On success stores `User`, token in Keychain |
| `AppLanguage` | `LocaleStore` | R/W | Persisted in `UserDefaults` (language code only — not sensitive) |

---

## UI States

### Loading State

- `GoogleSignInButton` shows a trailing `ProgressView` replacing the Google
  icon; label dims to `.secondary`.
- Button `isEnabled = false`; language chip remains interactive.
- No full-screen spinner — the OAuth WebAuth sheet is the dominant UI.

### Error State

- Uses a SwiftUI `.alert(_:isPresented:)` modal with a single "OK" action.
- For the "unauthorised email" case, alert auto-dismisses and app navigates to
  `[iOS] Access denied` (which has its own retry CTA).

### Success State

- Short success haptic (`UINotificationFeedbackGenerator.success`).
- Animated navigation to `[iOS] Home` (`navigationDestination(for: AppRoute.home)`).
- No success toast — the destination change is confirmation enough.

### Empty State

- N/A.

---

## Accessibility (Principle II)

| Requirement | Implementation |
|-------------|----------------|
| VoiceOver label on CTA | `"Đăng nhập bằng Google"` (localised) |
| VoiceOver label on language chip | `"Ngôn ngữ hiện tại: Tiếng Việt. Nhấn để đổi."` |
| Touch targets | CTA ≥ 44 pt height; language chip wrapped in 44×44 pt tap area |
| Dynamic Type | Welcome text and button label scale to AX5 without clipping; hero logo keeps intrinsic size |
| Colour contrast | CTA background vs. label MUST meet ≥ 4.5:1 in light and dark |
| Focus order | Language chip → hero → CTA → footer |
| Reduced motion | Disable any button shimmer; OAuth sheet transition is system-controlled |

---

## Responsive Behavior

| Device class | Layout |
|--------------|--------|
| iPhone (compact width, portrait) | Single column, as per design; hero vertically centred between header and CTA |
| iPhone landscape | Content scrolls; hero logo shrinks to 120 pt; CTA remains pinned to lower half |
| iPad | Same layout, max-width 480 pt, horizontally centred; background image fills |

---

## Analytics Events (Optional)

| Event | Trigger | Properties |
|-------|---------|------------|
| `login.viewed` | On appear | `{ locale }` |
| `login.google_tapped` | CTA tap | `{ locale }` |
| `login.success` | OAuth + allowlist pass | `{ user_id, provider: "google" }` |
| `login.denied` | Domain allowlist fail | `{ email_domain }` — domain only; DO NOT log full email (Principle V) |
| `login.error` | Any failure | `{ code }` — no PII, no tokens |

---

## Design Tokens (to confirm at implementation time)

| Token | Usage |
|-------|-------|
| `Color("BrandPrimary")` | CTA background |
| `Color("BrandOnPrimary")` | CTA label + icon |
| `Color("TextPrimary")` | Welcome copy |
| `Color("TextSecondary")` | Copyright footer |
| SF Symbol `chevron.down` | Language chip |
| Custom asset `logo_saa2025` | Hero logo |

---

## Implementation Notes (iOS / Supabase — Constitution-aligned)

### Dependencies (Principle I + III)

- `supabase-swift` for Auth.
- `RxSwift` + `RxRelay` for ViewModel I/O; bridged to SwiftUI via a
  `LoginStateAdapter: ObservableObject` (Principle III, no Rx in the View).
- `ASWebAuthenticationSession` (system) for the OAuth sheet.

### Security (Principle V)

- Only the Supabase **anon key** is bundled; never the service-role key.
- Session tokens MUST be written to Keychain with
  `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`.
- The email-domain allowlist is a **client-side navigation gate**, not a
  security boundary. The authoritative controls are Supabase RLS policies on
  every user-accessible table (see `backend.md`). Do not widen the allowlist
  expecting the UI alone to keep data safe.
- Allowlist is loaded from `Config/*.xcconfig` (default `sun-asterisk.com`;
  non-prod may add `gmail.com`).
- On allowlist failure the app MUST call `signOut()` before navigating so no
  Supabase session remains on device.
- No email, access token, or refresh token may appear in logs.
- App Transport Security: no exceptions.

### Clean Architecture touch-points (Principle I)

- **Presentation**: `Presentation/Auth/Views/LoginView.swift`,
  `Presentation/Auth/ViewModels/LoginViewModel.swift`,
  `Presentation/Auth/ViewModels/LoginStateAdapter.swift`.
- **Domain**: `Domain/UseCases/SignInWithGoogleUseCase.swift`,
  `Domain/UseCases/CheckEmailDomainUseCase.swift`,
  `Domain/Repositories/AuthRepository.swift`,
  `Domain/Entities/AllowedEmailDomains.swift` (value object loaded from config).
- **Data**: `Data/Repositories/AuthRepositoryImpl.swift`,
  `Data/Remote/Auth/SupabaseAuthDataSource.swift`,
  `Data/Local/Auth/KeychainSessionStorage.swift`,
  `Core/Config/AppConfig.swift` (reads `ALLOWED_EMAIL_DOMAINS` from
  `Info.plist`).

### Edge cases

- App launched from background after long idle → SDK refresh fires silently;
  if it fails the user lands on Login again without a visible error.
- Google SSO returns an email whose domain is not in `ALLOWED_EMAIL_DOMAINS`
  → app signs out immediately before navigating to Access denied, so no
  Supabase session remains in Keychain.
- Biometric re-auth: out of scope for v1; see Backlog.

---

## Analysis Metadata

| Property | Value |
|----------|-------|
| Analyzed By | `/momorph.screenflow` |
| Analysis Date | 2026-04-24 |
| Source | `get_overview` on screen `8HGlvYGJWq` (depth 4) |
| Needs Deep Analysis | No — structure is simple; styles will be fetched at implement-ui time |
| Confidence Score | High (navigation to Home / Access denied / Language dropdown all inferable from frame names and design context) |

### Next Steps

- [x] Allowlist: **client-side email-domain check**, default `sun-asterisk.com`, configurable to add `gmail.com` (decision: 2026-04-24).
- [x] Supported languages v1: **`VN` + `EN`** (no `JP` for v1).
- [ ] Run `/momorph.specs 9ypp4enmFmdK3YAFJLIu6C 8HGlvYGJWq` to extract detailed component specs + design tokens.
- [ ] Implement per `/momorph.implement-ui` against screen `8HGlvYGJWq`.
