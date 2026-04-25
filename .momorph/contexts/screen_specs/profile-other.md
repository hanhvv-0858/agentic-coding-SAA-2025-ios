# Screen: [iOS] Profile người khác

## Screen Info

| Property | Value |
|----------|-------|
| **Figma Frame ID** | `bEpdheM0yU` (node `6885:10395`) |
| **Figma Link** | https://momorph.ai/files/9ypp4enmFmdK3YAFJLIu6C/screens/bEpdheM0yU |
| **Screen Group** | Core App |
| **Platform** | iOS (SwiftUI) |
| **Status** | discovered |
| **Discovered At** | 2026-04-24 |
| **Last Updated** | 2026-04-24 |

---

## Description

`[iOS] Profile người khác` shows another user's public profile. It reuses
the identity + badge collection + kudos-list organisms from
`[iOS] Profile bản thân` but **removes self-only affordances** and adds a
single new CTA: **"Gửi lời cảm ơn và ghi nhận tới <Name>"** — a
pre-filled shortcut into `[iOS] Sun*Kudos_Gửi lời chúc Kudos` with the
recipient already selected.

Structural diff vs. `[iOS] Profile bản thân`:

| Block | Self | Other |
|-------|------|-------|
| Identity (MemberBlock + LevelBadge) | ✅ | ✅ |
| Badge collection | ✅ (6 slots, generic) | ✅ **with named labels** (REVIVAL, TOUCH OF LIGHT, STAY GOLD, FLOW TO HORIZON, BEYOND THE BOUNDARY, ROOT FUTHER) |
| Stats dashboard (kudos / hearts / secret boxes) | ✅ | ❌ **removed** |
| Primary CTA | "Mở Secret Box" (self-only) | **"Gửi lời cảm ơn và ghi nhận tới ..."** |
| Kudos filter (Đã nhận / Đã gửi) | ✅ toggle | ❌ **received-only**, no filter dropdown |
| Kudos list | ✅ | ✅ (received kudos only) |
| Tab Bar | ✅ | ✅ (tab context is preserved — this screen is pushed above the current tab) |

Data privacy: another user's **sent** kudos are not exposed, and their
stats are not exposed.

The overview also confirms the **canonical SAA 2025 badge taxonomy** — a
fixed set of **6 named badges**, matching Notification N6 copy
("đã thu thập đủ 6 huy hiệu của SAA").

---

## Navigation Analysis

### Incoming Navigations (From)

| Source | Trigger | Condition |
|--------|---------|-----------|
| `[iOS] Sun*Kudos_View kudo` | Tap sender or recipient avatar/name (where it is not self) | `userId != auth.uid()` → push this screen; otherwise push Profile bản thân |
| `[iOS] Sun*Kudos` (feed card) | Same as above | — |
| `[iOS] Sun*Kudos_Search Sunner` | Tap search result | Always other |
| Deep link | `app://profile/:userId` | Any time |
| `[iOS] Profile bản thân` (kudos card avatar) | Tap sender/recipient of one of my kudos | Only when that avatar is another user |

### Outgoing Navigations (To)

| Target | Trigger Element | Node ID | Confidence | Notes |
|--------|-----------------|---------|------------|-------|
| `[iOS] Language dropdown` | Language chip | `I6885:10400;88:1829` | High | Shared fold-in component |
| `[iOS] Sun*Kudos_Search Sunner` (TBC) | Search icon | `I6885:10400;88:1869` | Medium | Same TBC as Home / Profile me |
| `[iOS] Notifications` | Bell icon | `I6885:10400;88:1830` | High | — |
| `[iOS] Sun*Kudos_Gửi lời chúc Kudos` (`PV7jBVZU1N`) | Button "Gửi lời cảm ơn và ghi nhận tới \<Name\>" | `6885:10427` | High | **Push with `recipientId` pre-filled** — the compose screen must accept a route parameter |
| `[iOS] Sun*Kudos_View kudo` | Tap a kudo card | `6885:10421-10425` | High | `kudoId` in payload |
| Tab switch | Tab Bar | `6885:10428` | High | Inherits current tab context |

### Not present on this screen (vs. self)

- **No "Mở Secret Box" CTA** — that's a self-only affordance.
- **No stats dashboard**.
- **No filter dropdown** — only received kudos are shown; no
  list of choices (`mms_7_dropdown` does NOT include a `Dropdown-List`
  child unlike Profile bản thân).

### Navigation Rules

- **Auth required**: **Yes**.
- **Back behavior**: standard pop to whatever pushed.
- **Deep link**: `app://profile/:userId`. If `:userId == auth.uid()`,
  the router rewrites to `app://profile/me` and lands on Profile bản
  thân — prevents inconsistent states.
- **Tab Bar**: visible (inherits tab context from the pushing screen).

---

## Component Schema

### Layout Structure

```
┌─────────────────────────────────────┐
│ StatusBar                            │
├─────────────────────────────────────┤
│ [Logo]  [🇻🇳 VN ▾] [🔍] [🔔•]        │ ← mms_1_header (shared)
├─────────────────────────────────────┤
│          ┌────────┐                  │
│          │ Avatar │                  │ ← mms_2_member
│          └────────┘                  │
│        Huỳnh Dương Xuân Nhật         │
│        CEVC3 • [Rising Hero]         │
├─────────────────────────────────────┤
│ Bộ sưu tập icon của tôi              │ ← mms_4 (title — localisation flag)
│ ┌──────┐ ┌──────┐ ┌──────┐          │
│ │  🎖  │ │  🎖  │ │  🎖  │          │
│ │REVIVAL│ │TOUCH │ │STAY │          │ ← mms_3_list — 6 named badges
│ │      │ │OF LIGHT│ │GOLD │          │
│ └──────┘ └──────┘ └──────┘          │
│ ┌──────┐ ┌──────┐ ┌──────┐          │
│ │ FLOW │ │BEYOND│ │ROOT │          │
│ │  TO  │ │THE   │ │FURTHER│         │
│ │HORIZON│ │BOUND.│ │      │          │
│ └──────┘ └──────┘ └──────┘          │
│                                      │
│   ┌──────────────────────────────┐   │
│   │ ✉  Gửi lời cảm ơn và ghi    │   │ ← mms_A.1 primary CTA
│   │    nhận tới <Name>          │   │
│   └──────────────────────────────┘   │
├─────────────────────────────────────┤
│ Sun* Annual Awards 2025 / KUDOS      │ ← mms_6_header
│  Đã nhận 5 kudos                     │ ← mms_7_dropdown (LABEL ONLY, no options)
│                                      │
│ ┌──────────────────────────────┐     │ ← Kudo cards × N
│ │ [👤→👤] …                     │     │
│ │ 10:00 - 10/30/2025            │     │
│ │ #Dedicated #Inspring          │     │
│ │ ❤ 1,000     [btn][btn]       │     │
│ └──────────────────────────────┘     │
│ …                                    │
├─────────────────────────────────────┤
│ [SAA] [Awards] [Kudos] [Profile]    │ ← Tab Bar (shared)
└─────────────────────────────────────┘
```

### Component Hierarchy

```
ProfileOtherScreen (SwiftUI View)
├── HomeHeader (shared)                              # mms_1_header
├── BackgroundImage (Atom)
├── MemberBlock (shared Organism)                    # mms_2_member — same component as self
├── BadgeCollection (Organism)                       # mms_3_list
│   ├── CollectionTitle (Atom)                       # mms_4 (localisation flag, see below)
│   └── BadgeGridNamed (Molecule, 6 items)
│       └── BadgeCellNamed ×6
│           ├── BadgeArtwork (Atom)
│           └── BadgeNameLabel (Atom)                # REVIVAL / TOUCH OF LIGHT / STAY GOLD / …
├── SendKudoCTA (Molecule)                           # mms_A.1_Button ghi nhận
│   ├── MailIcon (Atom)
│   └── Label "Gửi lời cảm ơn và ghi nhận tới \(name)"
├── SectionHeader (shared)                           # mms_6_header
├── ReceivedKudosCountLabel (Atom)                   # mms_7_dropdown (label only)
├── KudosList (Organism, received-only)              # mms_8_kudos list
│   └── KudoCard ×N (shared Organism)
└── BottomTabBar (shared)                            # mms_9_nav bar
```

### Main Components

| Component | Type | Node ID | Description | Reusable |
|-----------|------|---------|-------------|----------|
| `MemberBlock` | Organism | `6885:10401` | **Same** shared organism as Profile bản thân | ✅ (introduced in profile-me.md) |
| `BadgeCollection` variant "Named" | Organism | `6885:10411` | Named grid — 6 badges w/ labels | ✅ (likely the canonical rendering; Profile me may upgrade to this layout) |
| `SendKudoCTA` | Molecule | `6885:10427` | Pre-filled shortcut to Gửi lời chúc | No (Profile-other-only) |
| `KudoCard` | Organism | `6885:10421` … | Same shared component | ✅ (introduced in profile-me.md) |
| `ReceivedKudosCountLabel` | Atom | `6885:10419` | Label only — no dropdown here | No |
| `BottomTabBar` | Organism | `6885:10428` | Shared | ✅ |

### Localisation flag

The title `"Bộ sưu tập icon của tôi"` is literally "**My** icon
collection", but on another user's profile this should say "của \<Name\>"
(or "của bạn ấy"). Treat the Figma text as a placeholder and provide two
keys:

- `profileOther.badges.title` → VN `"Bộ sưu tập huy hiệu của {name}"`,
  EN `"\(name)'s badge collection"`.

---

## Form Fields (If Applicable)

Not applicable.

---

## API Mapping

Backend: **Supabase**. Re-uses the `profile`, `badges_owned`, and
`kudos` endpoints introduced in `profile-me.md`, just parameterised
with `:userId` of the target rather than `auth.uid()`.

### On Screen Load / Resume

| Call | Method | Purpose | Response usage |
|------|--------|---------|----------------|
| `supabase.auth.getSession()` | SDK local | Auth guard | Redirect to Login if invalid |
| `supabase.from("profiles").select("*, department(*), level(*)").eq("user_id", userId).single()` | GET `/rest/v1/profiles` | Identity | Populate MemberBlock |
| `supabase.from("badges_owned").select("badge_id, badges(*)").eq("user_id", userId)` | GET `/rest/v1/badges_owned` | Badge collection | Populate BadgeCollection |
| `supabase.from("kudos").select(...).eq("recipient_id", userId).eq("status", "active").order("created_at", desc: true).limit(20)` | GET `/rest/v1/kudos` | Received kudos feed | Populate list + header count |
| `supabase.from("kudos").select(count:"exact", head:true).eq("recipient_id", userId).eq("status","active")` | HEAD | Received kudos count for header ("Đã nhận N kudos") | — |

Intentionally **no** calls to `profile_stats` or to query `sender_id =
userId` — privacy boundary.

### On User Action

| Action | Call | Method | Request | Response |
|--------|------|--------|---------|----------|
| Pull-to-refresh | Re-run all | — | — | Update all blocks |
| Scroll to bottom | Keyset pagination | GET | — | Append kudos page |
| Tap "Gửi lời cảm ơn tới \<Name\>" | — | navigation | — | Push `[iOS] Sun*Kudos_Gửi lời chúc Kudos` with `recipientId = userId`; prefill `recipient` field |
| Tap kudo card | — | navigation | — | Push `[iOS] Sun*Kudos_View kudo(id)` |
| Tap heart on a kudo | `supabase.rpc("toggle_heart", { kudo_id })` | POST | `{ kudo_id }` | Optimistic; same RPC as Profile me |
| Tap language chip / search / bell | — | navigation | — | Same shared destinations |

### Error Handling

| Error | Source | UI action |
|-------|--------|-----------|
| Session expired | Guard | Redirect to Login |
| Profile fetch failed | REST 5xx | Full-screen retry card (identity is load-bearing) |
| Badges fetch failed | REST | Hide badge section; do not block others |
| Kudos fetch failed | REST | Inline retry row |
| Toggle-heart failed | REST | Revert optimistic toggle |
| User not found (404) | REST returns empty | Navigate to `[iOS] Not Found` with `source: .internalNav` |
| Target is current user (misuse of route) | Client-side | Rewrite to `app://profile/me` before pushing |

---

## State Management

### Local State (ViewModel — Principle III)

```swift
protocol ProfileOtherViewModel {
    // Inputs
    let userId: UserID                 // injected at construction (route param)
    var viewAppeared: PublishRelay<Void> { get }
    var pullToRefresh: PublishRelay<Void> { get }
    var reachedEnd: PublishRelay<Void> { get }
    var sendKudoTapped: PublishRelay<Void> { get }
    var kudoTapped: PublishRelay<KudoID> { get }
    var heartToggled: PublishRelay<KudoID> { get }

    // Outputs
    var identity: Driver<ProfileIdentityVM?> { get }
    var badges: Driver<[NamedBadgeVM]> { get }
    var receivedCount: Driver<Int> { get }
    var kudos: Driver<[KudoCardVM]> { get }
    var isLoading: Driver<Bool> { get }
    var isPaginating: Driver<Bool> { get }
    var navigate: Signal<AppRoute> { get }
    var errorToast: Signal<String> { get }
}
```

No filter state — this screen only shows received kudos.

### Global State

| State | Store | R/W | Purpose |
|-------|-------|-----|---------|
| `AuthState` | `AuthStore` | R | Guard |
| `CurrentUser` | `AuthStore` | R | To compare `userId == auth.uid()` and rewrite route if so |
| `UnreadNotificationCount` | `NotificationStore` | R | Header bell dot (shared) |

---

## UI States

### Loading State

- Identity, badges, and kudos list each render skeletons independently.

### Error State

- Identity error → full-screen retry card.
- Other blocks degrade independently.

### Success State

- All blocks populated; header reads "Đã nhận \(n) kudos"; kudos list
  rendered.

### Empty State

- **No badges owned**: friendly copy "Người này chưa có huy hiệu."
- **No received kudos**: friendly copy + optional CTA "Bạn là người đầu
  tiên?" → triggers the same Send-Kudos action.

---

## Accessibility (Principle II)

| Requirement | Implementation |
|-------------|----------------|
| Screen context | Announce on appear: `"Hồ sơ của \(name)"` |
| VoiceOver — identity | Composite label (name + dept + level) |
| VoiceOver — badge cell | `"\(badgeName). \(localizedBadgeDescription)"` where description comes from a static asset table |
| VoiceOver — Send Kudo CTA | `.isButton`; hint: `"Viết lời ghi nhận gửi tới \(name)"` |
| VoiceOver — received count | `"Đã nhận \(n) lời ghi nhận"` — announced as the header of the list |
| Touch targets | CTA ≥ 44 pt; badge cells ≥ 44×44 |
| Dynamic Type | Badge names wrap to 2 lines at AX3+; grid collapses to 2 columns at AX5 |
| Focus order | Header → Identity → Badges → Send Kudo CTA → Kudos list → Tab bar |
| Localisation | All strings via `Localizable.xcstrings`; use the `{name}` interpolation for the CTA and title |

---

## Responsive Behavior

| Device class | Layout |
|--------------|--------|
| iPhone portrait | 3-column badge grid |
| iPhone landscape | Same; kudos list inherits width |
| iPad | Max width 600 pt, centered |
| AX3+ | Badge grid 2 columns; names wrap |

---

## Analytics Events (Optional)

| Event | Trigger | Properties |
|-------|---------|------------|
| `profile_other.viewed` | On appear | `{ department }` (no user name, no user id) |
| `profile_other.send_kudo_tap` | CTA tap | — |
| `profile_other.kudo_tap` | Kudo card tap | — |
| `profile_other.heart_toggled` | Heart tap | `{ new_state }` |

Principle V: **never log the viewed user's name or user_id** to avoid
building relationship graphs in analytics. Use `department` at most if
product needs it.

---

## Design Tokens

Same as Profile bản thân for identity + kudo card tokens. Additional:

| Token | Usage |
|-------|-------|
| Font `.headline` | Badge name |
| `Color("BadgeNameText")` | Badge label tint |
| Gradient tokens per badge type (REVIVAL / TOUCH OF LIGHT / STAY GOLD / FLOW TO HORIZON / BEYOND THE BOUNDARY / ROOT FUTHER) | Badge artwork backgrounds — resolve via `/momorph.specs` |

Badge asset naming:

```swift
enum BadgeKind: String, Codable {
    case revival, touchOfLight, stayGold, flowToHorizon, beyondTheBoundary, rootFurther
}

// Image("badge_\(badgeKind.rawValue)")
```

Note the intentional rename `rootFurther` in code — the Figma copy reads
`"ROOT FUTHER"` (likely a typo); keep the display string as designed but
use the corrected spelling for identifiers. Confirm spelling with design
before lock-in.

---

## Implementation Notes

### Clean Architecture touch-points (Principle I)

- **Presentation**:
  `Presentation/Profile/Views/ProfileOtherView.swift`,
  `Presentation/Profile/ViewModels/ProfileOtherViewModel.swift`,
  `Presentation/Profile/ViewModels/ProfileOtherStateAdapter.swift`,
  `Presentation/Profile/Components/BadgeGridNamedView.swift`,
  `Presentation/Profile/Components/SendKudoCTAView.swift`.
- **Shared (already introduced in profile-me.md)**:
  `Presentation/Shared/Components/MemberBlockView.swift`,
  `Presentation/Shared/Components/LevelBadgeView.swift`,
  `Presentation/Shared/Components/KudoCardView.swift`.
- **Domain**:
  `Domain/UseCases/FetchProfileByUserIdUseCase.swift`,
  `Domain/UseCases/FetchKudosReceivedByUserUseCase.swift`,
  `Domain/Entities/NamedBadge.swift` (enum + display name + description keys).
- **Data**: reuses `ProfileRepository`, `BadgeRepository`, `KudoRepository`
  from Profile bản thân with the `userId` parameter.

### Reactive model (Principle III)

- **Initial load**: parallel `Single` for identity, badges, kudos count,
  first kudos page — progressive rendering as each resolves.
- **Pagination**: keyset on `created_at`, same pattern as Profile bản thân.
- **Send Kudo CTA**: emits `Signal<AppRoute>.sunKudos(.writeKudo(recipientId: userId))` — Gửi lời chúc's ViewModel must accept an optional `recipientId` to prefill.

### Security (Principle V)

- **Privacy boundaries enforced server-side**:
  - `kudos.SELECT` RLS must expose only `status = 'active'` rows to the
    viewer **unless** the viewer is the author (authors can see their own
    soft-hidden/spam — handled by Profile bản thân).
  - A user's **sent** kudos are NOT fetched by this screen; client must
    not expose an escape hatch.
  - `profile_stats(uid)` must NOT be called for other users — either
    server-side restrict the RPC to `auth.uid() == uid`, OR simply do
    not call it here.
- Avoid logging user identifiers / names.

### Edge cases

- User is viewing their own profile via an `app://profile/:userId` deep
  link → router rewrites to `app://profile/me` and lands on Profile bản
  thân — single source of truth.
- Target user is soft-deleted / suspended → REST returns empty → route
  to `[iOS] Not Found`.
- Sending Kudos to self is disallowed in the compose screen — so the CTA
  only shows when `userId != auth.uid()`. Since the router already
  rewrites, this should never appear anyway; double-guard in the
  ViewModel.
- Badges labelled `ROOT FUTHER` (typo in design) — see Design Tokens
  note; do not silently "fix" the display string; confirm with design.

---

## Analysis Metadata

| Property | Value |
|----------|-------|
| Analyzed By | `/momorph.screenflow` |
| Analysis Date | 2026-04-24 |
| Source | `get_overview` on `bEpdheM0yU` (depth 5) |
| Needs Deep Analysis | No |
| Confidence Score | High |

### Next Steps

- [ ] Confirm **canonical 6-badge taxonomy** with design: REVIVAL,
      TOUCH OF LIGHT, STAY GOLD, FLOW TO HORIZON, BEYOND THE BOUNDARY,
      ROOT FUTHER (typo? expect "FURTHER"). Lock into DB enum / seed.
- [ ] Confirm localisation strategy for the badge-collection title on
      other profiles (use `{name}` interpolation).
- [ ] Confirm `kudos` RLS: authors may read their own soft-hidden
      content; others only see `status = 'active'`.
- [ ] Add recipient-prefill support to `[iOS] Sun*Kudos_Gửi lời chúc
      Kudos` (route parameter `recipientId` + compose ViewModel input).
- [ ] Decide whether the "named-badge with label" grid layout is the
      universal representation — if so, backport to Profile bản thân so
      both screens share exact same BadgeCollection organism.
