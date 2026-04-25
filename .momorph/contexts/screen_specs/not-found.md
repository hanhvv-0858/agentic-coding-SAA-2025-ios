# Screen: [iOS] Not Found

## Screen Info

| Property | Value |
|----------|-------|
| **Figma Frame ID** | `sn2mdavs1a` (node `6885:9448`) |
| **Figma Link** | https://momorph.ai/files/9ypp4enmFmdK3YAFJLIu6C/screens/sn2mdavs1a |
| **Screen Group** | Error states |
| **Platform** | iOS (SwiftUI) |
| **Status** | discovered |
| **Discovered At** | 2026-04-24 |
| **Last Updated** | 2026-04-24 |

---

## Description

`[iOS] Not Found` is the iOS equivalent of a generic **404** screen. It is
shown when the user navigates to a resource that does not exist or has been
removed — for example, a deep link into a deleted Kudos post, a stale
notification pointing at a missing Award, or any navigation target that
fails its fetch with a "resource not found" error from Supabase.

Content:

- Title: **"NOT FOUND"**
- Subtitle: *"The resource you're looking for doesn't exist or has been removed."*
- A `Not Found` illustration (shared `MM_MEDIA_Not Found` asset — same asset
  used by `[iOS] Access denied`).
- A single primary button: **"Go back to Home"**.
- A top navigation bar with a **Back** icon (no title).

Layout is **structurally identical** to `[iOS] Access denied` (same
organism: `ErrorStateView` — see Implementation Notes). The two screens
differ only in copy and destination.

---

## Navigation Analysis

### Incoming Navigations (From)

| Source | Trigger | Condition |
|--------|---------|-----------|
| Any authenticated screen | Navigation target raised `Error.notFound` on fetch | Backend returned empty / 404-equivalent for the requested row |
| Deep link handler | App launched with a `app://` URL pointing at a stale/missing resource | After auth check passes |
| Notification tap | User taps a notification whose subject resource was deleted | Resource fetch returns empty |

### Outgoing Navigations (To)

| Target | Trigger Element | Node ID | Confidence | Notes |
|--------|-----------------|---------|------------|-------|
| `[iOS] Home` | Button "Go back to Home" | `6885:9489` | High | User is authenticated on Not Found — routes to the SAA tab root |
| (previous screen, if any) | Back Icon in TopNavigation | `6885:9467` | High | Pops one level of the navigation stack |

### Navigation Rules

- **Back behavior**: Pop the current navigation frame. If this screen is
  the root of a push (e.g. deep-link landing), Back falls through to Home.
- **Deep link support**: Not a deep-link destination itself. It is a
  *result* screen shown when another deep link fails.
- **Auth required**: **Yes** (typical case). If somehow reached in an
  unauthenticated state, the "Go back to Home" button routes to `[iOS]
  Login` instead — the button handler reads `AuthState` at tap time.
- **Tab Bar**: keep visible (this is inside the authenticated shell); user
  can also switch tabs to escape the error.

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
│            NOT FOUND                 │ ← Title (H2)
│           ───────────                │ ← divider
│ The resource you're looking for      │
│ doesn't exist or has been removed.   │ ← Subtitle
│                                      │
│                                      │
│        [ Illustration ]              │ ← mms_3.1 (shared asset)
│                                      │
│                                      │
│                                      │
│   ┌─────────────────────────────┐    │
│   │     Go back to Home         │    │ ← mms_3.2 primary button
│   └─────────────────────────────┘    │
│                                      │
└─────────────────────────────────────┘
```

### Component Hierarchy

```
NotFoundScreen (SwiftUI View)
└── ErrorStateView (shared Organism — introduced by this spec)
    ├── TopNavigation (shared Organism)
    │   ├── StatusBar (system)
    │   └── TopNavigationContent (Molecule)
    │       ├── BackIconButton (Atom)                # 6885:9467
    │       └── TitleSlot (empty)
    ├── BackgroundImage (Atom)                       # bg
    └── ErrorStateContent (Organism)                 # mms_3
        ├── Header (Molecule)
        │   ├── TitleLabel "NOT FOUND"               # 6885:9483
        │   ├── Divider (Atom)                       # Rectangle 16
        │   └── SubtitleLabel (Atom, localised)      # 6885:9486
        ├── Illustration (Atom)                      # mms_3.1 (MM_MEDIA_Not Found)
        └── PrimaryButton (Atom, configurable)       # mms_3.2 → Home
```

### Main Components

| Component | Type | Node ID | Description | Reusable |
|-----------|------|---------|-------------|----------|
| `ErrorStateView` | Organism | *new shared* | Reusable wrapper for title + subtitle + illustration + primary button. Drives both `[iOS] Not Found` and `[iOS] Access denied`. | **Yes — shared** |
| `TopNavigation` | Organism | `6885:9452` | App-wide iOS-style nav bar | Shared |
| `Illustration (Not Found asset)` | Atom | `6885:9487` | Uses the `MM_MEDIA_Not Found` asset | Shared with Access denied |
| `PrimaryButton` | Atom | `6885:9489` | Same style as Login CTA | Shared |

Design note (non-blocking): the content block is named
`mms_3_Open secret box- chưa mở` in Figma — carry-over of a base frame, not
semantically meaningful. Ignore the name; follow rendered content.

---

## Form Fields (If Applicable)

Not applicable.

---

## API Mapping

**No network calls** are made on this screen. It is a result state produced
by a *failed* fetch elsewhere — the caller has already surfaced the error
and routed the user here.

### On User Action

| Action | Call | Method | Request | Response |
|--------|------|--------|---------|----------|
| Tap "Go back to Home" | — | navigation | — | `AppRoute` set to `.home` if `AuthState == .signedIn`, else `.login`; navigation stack reset |
| Tap Back (top nav) | — | navigation | — | Pop one level; if stack is empty, fall through to `.home` |

### Error Handling

N/A — Not Found *is* an error presentation. If somehow the "Go back to
Home" action fails (unexpected), fall back to `.login` and log a warning.

---

## State Management

### Local State (ViewModel — Principle III)

The screen is stateless from a data-fetching perspective. A minimal
ViewModel keeps parity with the rest of the codebase and routes taps via
Rx.

```swift
protocol NotFoundViewModel {
    // Inputs
    var primaryTapped: PublishRelay<Void> { get }
    var backTapped: PublishRelay<Void> { get }

    // Outputs
    var navigate: Signal<AppRoute> { get }     // .home or .login (context-sensitive)
}
```

Context-awareness: the `primaryTapped` handler reads `AuthStore.state` at
tap time (not on appear) so the destination correctly reflects the current
auth state.

### Global State

| State | Store | R/W | Purpose |
|-------|-------|-----|---------|
| `AuthState` | `AuthStore` | R | Decide destination for "Go back to Home" |
| `AppRoute` | `AppRouter` | W | Reset stack on tap |

---

## UI States

### Loading State

N/A — no network calls.

### Error State

N/A for this screen itself. It *is* the error presentation.

### Success State

N/A.

### Empty State

N/A.

---

## Accessibility (Principle II)

| Requirement | Implementation |
|-------------|----------------|
| VoiceOver — title | `.accessibilityAddTraits(.isHeader)` on `"NOT FOUND"` |
| VoiceOver — subtitle | Read after title in the same live container |
| VoiceOver — button | Label: the localised button text; trait `.isButton`; hint: `"Quay về màn chính"` / `"Returns to the Home tab"` |
| Touch targets | Primary button ≥ 44 pt height; Back icon wrapped in 44×44 pt tap area |
| Dynamic Type | Title, subtitle and button scale to AX5; illustration scales down but never clips text |
| Colour contrast | Title / subtitle vs. background ≥ 4.5:1 in Light and Dark |
| Focus order | Back → Title → Subtitle → Primary button |
| Reduced motion | No animations |
| Localisation | All strings via `Localizable.xcstrings` keys (v1: VN + EN) |

---

## Responsive Behavior

| Device class | Layout |
|--------------|--------|
| iPhone portrait | As designed |
| iPhone landscape | Content in a `ScrollView`; illustration capped at 40% viewport height |
| iPad | Max width 480 pt, centered |

---

## Analytics Events (Optional)

| Event | Trigger | Properties |
|-------|---------|------------|
| `not_found.viewed` | On appear | `{ source }` — where the user came from (e.g. `"deeplink"`, `"notification"`, `"internal_nav"`) |
| `not_found.primary_tap` | Button tap | `{ source, auth_state }` |
| `not_found.back_tap` | Back icon tap | `{ source }` |

Do NOT log the attempted resource ID if it might contain sensitive
identifiers — use a short taxonomy for `source` instead.

---

## Design Tokens

| Token | Usage |
|-------|-------|
| `Color("TextPrimary")` | Title |
| `Color("TextSecondary")` | Subtitle |
| `Color("BrandPrimary")` | Primary button background |
| `Color("BrandOnPrimary")` | Primary button label |
| Font: `.title2` → title, `.body` → subtitle, `.headline` → button label |
| Asset: `Image("not_found_illustration")` — shared with `[iOS] Access denied` |

All tokens are identical to `[iOS] Access denied`. If they remain identical
in implementation, they should live in a single `ErrorStateStyle` struct.

---

## Implementation Notes

### Clean Architecture touch-points (Principle I)

- **Presentation (shared)**: introduce
  `Presentation/Shared/Components/ErrorStateView.swift` — a reusable
  SwiftUI View that takes:
  ```swift
  struct ErrorStateView: View {
      let title: LocalizedStringKey
      let subtitle: LocalizedStringKey
      let illustration: Image
      let primaryAction: ErrorStateAction   // label + handler

      // optional — only Not Found needs it
      let onBack: (() -> Void)?
  }
  ```
  Both `NotFoundScreen` and `AccessDeniedScreen` become thin wrappers
  that instantiate this view with their specific strings, illustration
  (shared asset), and action.
- **Presentation (this screen)**:
  `Presentation/ErrorStates/Views/NotFoundView.swift`,
  `Presentation/ErrorStates/ViewModels/NotFoundViewModel.swift`.
- **Domain**: No new use cases. Consumes `AuthStore.state` at tap time.
- **Data**: None.

### Reactive model (Principle III)

- ViewModel exposes `Signal<AppRoute>` merged from `primaryTapped` and
  `backTapped`. The handler reads `AuthStore.state` synchronously when
  the tap fires and maps to `.home` or `.login`.
- Throttle taps with `.throttle(.milliseconds(300), scheduler: MainScheduler.instance)`
  to avoid double-pops.

### Security (Principle V)

- No data is fetched on this screen, so RLS is not in play here.
- Avoid echoing user-controlled IDs (e.g. a deleted `kudosId` from a deep
  link) into any log/analytics event — use a coarse `source` bucket.

### Shared component alignment with `[iOS] Access denied`

This spec **introduces** `ErrorStateView`. Update
[access-denied.md](access-denied.md) during implementation to consume the
same component instead of duplicating the layout. The Access denied
instance passes a different button action (routes to `.login`
unconditionally) via the `primaryAction` parameter.

### Edge cases

- User reaches Not Found via a notification whose subject has since been
  restored (race condition): tapping "Go back to Home" is safe; the user
  will see up-to-date data on Home.
- Multiple Not Found screens stacked (user taps through several stale
  deep links): Back button pops one at a time; primary button resets the
  whole stack.
- Tab Bar is still visible: switching tabs from Not Found is allowed and
  expected; this screen must not lock navigation.

---

## Analysis Metadata

| Property | Value |
|----------|-------|
| Analyzed By | `/momorph.screenflow` |
| Analysis Date | 2026-04-24 |
| Source | `get_overview` on `sn2mdavs1a` (depth 5) |
| Needs Deep Analysis | No |
| Confidence Score | High (structure trivial; shared layout with Access denied confirmed by overview comparison) |

### Next Steps

- [ ] When implementing, extract `ErrorStateView` first, then refactor
      `AccessDeniedScreen` to consume it (zero-regression change —
      pure structural refactor).
- [ ] Decide final VN + EN copy for title, subtitle, button — align
      with design:
      - VN key `notFound.title` → `"KHÔNG TÌM THẤY"` (suggested)
      - EN key `notFound.title` → `"NOT FOUND"`
      - VN key `notFound.subtitle` → `"Nội dung bạn tìm không tồn tại hoặc đã bị xoá."`
      - EN key `notFound.subtitle` → `"The resource you're looking for doesn't exist or has been removed."`
      - VN key `errorState.primaryButton` → `"Về màn chính"`
      - EN key `errorState.primaryButton` → `"Go back to Home"`
- [ ] Route registration: add `.notFound(source: NotFoundSource)` to
      `AppRoute` with `NotFoundSource` enum (`.deeplink`, `.notification`,
      `.internalNav`) so callers can tell the screen where the user came
      from for analytics.
