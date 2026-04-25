# Screen: [iOS] Access denied

## Screen Info

| Property | Value |
|----------|-------|
| **Figma Frame ID** | `k-7zJk2B7s` (node `6885:9490`) |
| **Figma Link** | https://momorph.ai/files/9ypp4enmFmdK3YAFJLIu6C/screens/k-7zJk2B7s |
| **Screen Group** | Authentication |
| **Platform** | iOS (SwiftUI) |
| **Status** | discovered |
| **Discovered At** | 2026-04-24 |
| **Last Updated** | 2026-04-24 |

---

## Description

`[iOS] Access denied` is a **terminal state screen** shown when a user
successfully completes Google OAuth but their email domain is **not** in
the configured allowlist (see constitution V + `login.md`). It is also
the generic fallback for a client-side 403 where the app detects that a
signed-in user lacks permission for a requested resource.

Content:

- Title: **"Access Denied"**
- Subtitle: *"You don't have permission to access this resource."*
- A `Not Found`-style illustration (`MM_MEDIA_Not Found` asset — reused
  between `[iOS] Not Found` and `[iOS] Access denied`, per design).
- A single primary button: **"Go back to Home"**.
- A top navigation bar with a **Back** icon (no title).

**Important UX note for implementation**: the button label says "Go back
to Home", but by the time the user reaches this screen the app has
already called `supabase.auth.signOut()` (see `login.md` → Error
Handling), so **there is no authenticated session**. The button must
therefore route to `[iOS] Login`, not to `[iOS] Home`. Before v1 ships,
raise with design whether the label should be relabelled (e.g.
`"Back to sign in"`) — but the *behaviour* is non-negotiable.

---

## Navigation Analysis

### Incoming Navigations (From)

| Source | Trigger | Condition |
|--------|---------|-----------|
| `[iOS] Login` | OAuth success + allowlist fail | App has just called `signOut()`; Keychain session cleared |
| (future) any authenticated screen | Server returns 403 / RLS denial for a navigation action | Client detects forbidden + routes here |

### Outgoing Navigations (To)

| Target | Trigger Element | Node ID | Confidence | Notes |
|--------|-----------------|---------|------------|-------|
| `[iOS] Login` | Button "Go back to Home" | `6885:9531` | High | Label says "Home" but app is unauthenticated — route MUST go to Login |
| `[iOS] Login` | Back Icon in TopNavigation | `6885:9509` | High | Equivalent behaviour to the button — unauthenticated users can only land on Login |

### Navigation Rules

- **Back behavior**: Back always returns to Login (the screen that sent the
  user here). Popping deeper history is not expected since the navigation
  stack is reset on sign-out.
- **Deep link support**: No. Access denied is a transient state, not a
  routable destination.
- **Auth required**: No — this screen is part of the unauthenticated stack.
- **Re-auth entry**: from Login the user can sign in with a different Google
  account; if the new account's domain passes the allowlist they land on
  `[iOS] Home`.

---

## Component Schema

### Layout Structure

```
┌─────────────────────────────────────┐
│ StatusBar                            │
├─────────────────────────────────────┤
│ [←]                                  │ ← TopNavigation (no title)
├─────────────────────────────────────┤
│                                      │
│           Access Denied              │ ← Title (H2)
│           ───────────                │ ← divider
│  You don't have permission to        │
│     access this resource.            │ ← Subtitle
│                                      │
│                                      │
│        [ Illustration ]              │ ← mms_2.1 (shared Not-Found art)
│                                      │
│                                      │
│                                      │
│   ┌─────────────────────────────┐    │
│   │     Go back to Home         │    │ ← mms_2.2 primary button
│   └─────────────────────────────┘    │
│                                      │
└─────────────────────────────────────┘
```

### Component Hierarchy

```
AccessDeniedScreen (SwiftUI View)
├── TopNavigation (Organism — shared)                # 6885:9494
│   ├── StatusBar (Atom — system)
│   └── TopNavigationContent (Molecule)
│       ├── BackIconButton (Atom)                    # 6885:9509 → pop
│       └── TitleSlot (empty)                        # 6885:9499
├── BackgroundImage (Atom)                           # bg / MM_MEDIA_Keyvisual
└── ContentCard (Organism)                           # mms_2
    ├── Header (Molecule)
    │   ├── TitleLabel "Access Denied"               # 6885:9525
    │   ├── Divider (Atom)                           # Rectangle 16
    │   └── SubtitleLabel (Atom, localised)          # 6885:9528
    ├── AccessDeniedIllustration (Atom)              # 6885:9529 (shared asset)
    └── PrimaryButton "Go back to Home"              # 6885:9531
```

### Main Components

| Component | Type | Node ID | Description | Reusable |
|-----------|------|---------|-------------|----------|
| `TopNavigation` | Organism | `6885:9494` | App-wide iOS-style nav bar; title slot is empty here | **Yes — shared** (will appear on many screens) |
| `BackIconButton` | Atom | `6885:9509` | Standard Back affordance | Yes — shared |
| `AccessDeniedIllustration` | Atom | `6885:9529` | Uses the `MM_MEDIA_Not Found` asset — same artwork as `[iOS] Not Found`. Prefer one asset with two wrappers than duplicating. | Shared between Access denied & Not Found |
| `PrimaryButton` | Atom | `6885:9531` | Same primary button style as `Login`'s CTA | Yes — shared |

Design note (non-blocking): the content block is named
`mms_2_Open secret box- chưa mở` in Figma — that's a designer carry-over
from copying the Secret Box layout as a base. It is **not** related to
Secret Box runtime behaviour; ignore the name, follow the rendered content.

---

## Form Fields (If Applicable)

Not applicable.

---

## API Mapping

**No network calls** are made on this screen. It is a pure presentation of
an error state that the caller (Login or any future 403 handler) has
already put the app into. By the time we reach Access denied:

- The Supabase session has been cleared (`signOut()` called in Login).
- The Keychain no longer holds any auth material for the denied account.
- The Domain layer has emitted `navigateAccessDenied` and the Router has
  performed the push.

### On User Action

| Action | Call | Method | Request | Response |
|--------|------|--------|---------|----------|
| Tap "Go back to Home" | — | navigation | — | `AppRoute` reset to `.login` — Login becomes the new stack root |
| Tap Back (top nav) | — | navigation | — | Same as above |

---

## State Management

### Local State (ViewModel — Principle III)

The screen is stateless from a data-fetching perspective. The ViewModel
exists only to route user taps through Rx so the screen stays consistent
with the rest of the codebase.

```swift
protocol AccessDeniedViewModel {
    // Inputs
    var primaryTapped: PublishRelay<Void> { get }
    var backTapped: PublishRelay<Void> { get }

    // Outputs
    var navigateLogin: Signal<Void> { get }
}
```

No `@Published` state beyond static labels; `AccessDeniedStateAdapter`
can therefore be trivial or omitted (the View binds the two taps via a
single `navigateLogin` signal).

### Global State

| State | Store | R/W | Purpose |
|-------|-------|-----|---------|
| `AuthState` | `AuthStore` | R | Sanity-assert that the user is unauthenticated on appear — if somehow a valid session exists, the app is in an inconsistent state and should log a warning |
| `AppRoute` | `AppRouter` | W | Reset stack root to `.login` on button tap |

---

## UI States

### Loading State

N/A — no network calls.

### Error State

N/A for this screen itself. It *is* the error state of Login's domain
check.

### Success State

N/A — there is no success action on this screen. The closest thing is
successfully navigating back to Login.

### Empty State

N/A.

---

## Accessibility (Principle II)

| Requirement | Implementation |
|-------------|----------------|
| VoiceOver — title | Announced as a header via `.accessibilityAddTraits(.isHeader)` on `"Access Denied"` |
| VoiceOver — subtitle | Read after the title automatically (live container group) |
| VoiceOver — button | Label: `"Go back to Home"` (or final localised text); trait `.isButton`; hint: `"Quay lại màn đăng nhập"` / `"Returns to sign-in"` — this hint tells the user the real destination, correcting the ambiguous label |
| Touch targets | Primary button ≥ 44 pt height; Back icon wrapped in 44×44 pt tap area |
| Dynamic Type | Title, subtitle and button scale to AX5; illustration does not clip (use `.fixedSize()` on the text stack, scroll container around it) |
| Colour contrast | Title / subtitle vs. background ≥ 4.5:1 in Light and Dark |
| Focus order | Back → Title → Subtitle → Primary button |
| Reduced motion | No animations on this screen |
| Localisation | Title + subtitle + button label MUST be keys in `Localizable.xcstrings` (v1: VN + EN) |

---

## Responsive Behavior

| Device class | Layout |
|--------------|--------|
| iPhone portrait | As designed |
| iPhone landscape | Content wrapped in a `ScrollView`; illustration scales down to ≤ 40% of viewport height |
| iPad | Max width 480 pt, centered |

---

## Analytics Events (Optional)

| Event | Trigger | Properties |
|-------|---------|------------|
| `access_denied.viewed` | On appear | `{ reason: "email_domain" }` (reason may expand if we route here from other 403 sources) |
| `access_denied.primary_tap` | Button tap | `{ reason }` |
| `access_denied.back_tap` | Back icon tap | `{ reason }` |

Do NOT log the denied email address (Principle V) — if a reason code is
needed, pass a short taxonomy value, not the email.

---

## Design Tokens

| Token | Usage |
|-------|-------|
| `Color("TextPrimary")` | Title |
| `Color("TextSecondary")` | Subtitle |
| `Color("BrandPrimary")` | Primary button background |
| `Color("BrandOnPrimary")` | Primary button label |
| Font: `.title2` → title, `.body` → subtitle, `.headline` → button label |
| Asset: `Image("not_found_illustration")` — shared with `[iOS] Not Found` |

---

## Implementation Notes

### Clean Architecture touch-points (Principle I)

- **Presentation**: `Presentation/Auth/Views/AccessDeniedView.swift`,
  `Presentation/Auth/ViewModels/AccessDeniedViewModel.swift`. No
  dedicated `StateAdapter` needed — View binds to the single Rx signal.
- **Domain**: No new use cases. The screen consumes the `AuthState` value
  object from `AuthStore` and the `AppRoute.login` value from
  `Presentation/Shared/Navigation/AppRoute.swift`.
- **Data**: None.

### Reactive model (Principle III)

- A single `Signal<Void>` (`navigateLogin`) merged from
  `primaryTapped` and `backTapped`. Observed by `AppRouter` to reset the
  navigation stack.

### Security (Principle V)

- On `onAppear`, assert no Supabase session remains in Keychain. If one
  is unexpectedly present, call `signOut()` defensively and log a
  `Logger.warning("AccessDenied shown with active session")` — never log
  the email or token (`.private` interpolation only).
- No data is fetched on this screen, so RLS is not in play here.

### Edge cases

- User taps Back rapidly → debounce taps; the Rx pipeline emits a single
  event (`throttle(.milliseconds(300), scheduler: MainScheduler.instance)`).
- User uses iOS edge-swipe back → equivalent to tapping Back; same
  destination (Login).
- Localisation check: button copy `"Go back to Home"` is misleading; when
  localisation keys are added in `Localizable.xcstrings`, consider using
  clearer VN/EN strings:
  - VN key `accessDenied.primaryButton` → `"Quay lại đăng nhập"`
  - EN key `accessDenied.primaryButton` → `"Back to sign in"`
  Leaving `"Go back to Home"` in v1 is acceptable, but flag to design.

---

## Analysis Metadata

| Property | Value |
|----------|-------|
| Analyzed By | `/momorph.screenflow` |
| Analysis Date | 2026-04-24 |
| Source | `get_overview` on `k-7zJk2B7s` (depth 5) |
| Needs Deep Analysis | No |
| Confidence Score | High (small, simple screen; the only uncertainty is the button-label-vs-behaviour mismatch, flagged above) |

### Next Steps

- [ ] Raise the `"Go back to Home"` label with design → decide on final VN
      + EN copy before implementation.
- [ ] Align with `[iOS] Not Found` on a shared `ErrorStateView` component
      (same layout: title + subtitle + illustration + primary button) — do
      this during the Not Found run.
- [ ] Run `/momorph.specs 9ypp4enmFmdK3YAFJLIu6C k-7zJk2B7s` for token-
      level detail when implementing.
