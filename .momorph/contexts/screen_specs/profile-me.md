# Screen: [iOS] Profile bản thân

## Screen Info

| Property | Value |
|----------|-------|
| **Figma Frame ID** | `hSH7L8doXB` (node `6885:10333`) |
| **Figma Link** | https://momorph.ai/files/9ypp4enmFmdK3YAFJLIu6C/screens/hSH7L8doXB |
| **Screen Group** | Core App |
| **Platform** | iOS (SwiftUI) |
| **Status** | discovered |
| **Discovered At** | 2026-04-24 |
| **Last Updated** | 2026-04-24 |

---

## Description

`[iOS] Profile bản thân` is the **current user's profile** — the root of the
`Profile` tab in the bottom Tab Bar. It aggregates five blocks for the
signed-in user: (1) identity (avatar + name + department + level/title),
(2) badge collection ("Bộ sưu tập icon của tôi"), (3) stats dashboard
(kudos received / sent / hearts + secret boxes opened / unopened) with a
primary CTA to **Mở Secret Box**, (4) a Kudos feed with a filter dropdown
that toggles between **Đã nhận** and **Đã gửi**, and (5) the shared
bottom Tab Bar.

This screen **confirms the Profile anchors** flagged during the
Notifications analysis:

- `.profile(.me).anchor(.level)` → scrolls to the identity block
  (`mms_1.1_member`, level badge "Legend Hero / Rising Hero").
- `.profile(.me).anchor(.badges)` → scrolls to the badge collection
  (`mms_2_icon collection`).

It shares structural DNA with `[iOS] Profile người khác` (`bEpdheM0yU`) —
the "other user" variant will lack self-only affordances (avatar edit,
Open Secret Box CTA, edit/delete on sent kudos).

---

## Navigation Analysis

### Incoming Navigations (From)

| Source | Trigger | Condition |
|--------|---------|-----------|
| `[iOS] Home` | Tab: Profile | Always |
| `[iOS] Notifications` | Tap N4 (Level up) | Anchors to `.level` |
| `[iOS] Notifications` | Tap N6 (Badge / prize) | Anchors to `.badges` |
| Deep link | `app://profile/me` | Always |

### Outgoing Navigations (To)

| Target | Trigger Element | Node ID | Confidence | Notes |
|--------|-----------------|---------|------------|-------|
| `[iOS] Language dropdown` | Tap language chip | `I6885:10338;88:1829` | High | Same shared component (sheet) |
| `[iOS] Sun*Kudos_Search Sunner` (TBC) | Tap 🔍 search icon | `I6885:10338;88:1869` | Medium | Destination TBC during Wave 5 |
| `[iOS] Notifications` | Tap 🔔 bell | `I6885:10338;88:1830` | High | — |
| Avatar editor (out of v1 scope?) | Tap avatar | `6885:10340` | Low | Design does not show an editor frame — treat as no-op v1 |
| `[iOS] Open secret box` (`kQk65hSYF2`) | Tap "Mở Secret Box" button | `6885:10386` | High | Self-only CTA |
| `[iOS] Sun*Kudos_View kudo` (`T0TR16k0vH`) | Tap a Kudo card body | `6885:10390-10392` | High | `kudoId` in payload |
| Kudo card inline buttons (edit / delete / share) | Buttons inside `Action` frame | `I6885:10390;105:5521` | Low | Exact actions not labelled in overview — resolve during `/momorph.specs` run |

### Top-bar / list-level actions (no navigation)

| Action | Effect |
|--------|--------|
| Tap dropdown "Đã gửi (N)" / "Đã nhận (N)" | Toggle the Kudos filter — local state switch + refetch |
| Pull-to-refresh | Refresh all blocks |
| Scroll to bottom of kudos list | Paginate next page |
| Heart on a kudo | Like/unlike toggle — updates heart count |

### Navigation Rules

- **Auth required**: **Yes** — the data is user-scoped.
- **Tab root**: no back button in header; swipe-back disabled inside tab.
- **Back from deep-link entry**: if reached via deep link with no stack
  parent, Back falls through to Home tab.
- **Deep link**: `app://profile/me` (default) and `app://profile/me?anchor=level|badges` (notification-driven).

---

## Component Schema

### Layout Structure

```
┌─────────────────────────────────────┐
│ StatusBar                            │
├─────────────────────────────────────┤
│ [Logo]  [🇻🇳 VN ▾] [🔍] [🔔•]        │ ← mms_1_header (shared with Home)
├─────────────────────────────────────┤
│          ┌────────┐                  │
│          │ Avatar │                  │ ← mms_1.1_member
│          └────────┘                  │
│        Huỳnh Dương Xuân Nhật         │
│        CEVC3 • [Legend Hero]         │   department • level badge
├─────────────────────────────────────┤
│ Bộ sưu tập icon của tôi              │ ← mms_2_icon collection
│ [🎖][🎖][🎖][🎖][🎖][🎖]              │   6 badges
├─────────────────────────────────────┤
│ Thống kê tổng quát                   │ ← mms_D.1
│   [5] Kudos nhận  [25] Kudos gửi     │
│   [25] ❤                             │
│   ─────────                          │
│   [25] Đã mở  [25] Chưa mở           │
│   ┌──────────────────────────────┐   │
│   │   Mở Secret Box              │   │ ← primary CTA
│   └──────────────────────────────┘   │
├─────────────────────────────────────┤
│ Sun* Annual Awards 2025 / KUDOS      │ ← mms_4_header
│ ┌────────────────────┐               │
│ │ Đã gửi (5) ▾       │               │ ← mms_dropdown (filter)
│ └────────────────────┘               │
│ ┌──────────────────────────────┐     │
│ │ [👤→👤] Trao nhận             │     │
│ │ 10:00 - 10/30/2025  IDOL…    │     │
│ │ [img][img][img][img]          │     │ ← Kudo card
│ │ #Dedicated #Inspring …        │     │
│ │ ❤ 1,000     [btn][btn]       │     │
│ └──────────────────────────────┘     │
│ ┌ … 2 more cards …                   │
├─────────────────────────────────────┤
│ [SAA] [Awards] [Kudos] [Profile]    │ ← Tab Bar
└─────────────────────────────────────┘
```

### Component Hierarchy

```
ProfileMeScreen (SwiftUI View — tab content)
├── HomeHeader (shared Organism)                      # mms_1_header (reused from Home)
├── BackgroundImage (Atom)
├── MemberBlock (Organism)                            # mms_1.1_member — anchor: .level
│   ├── AvatarView (Atom)                             # 6885:10340
│   ├── NameLabel (Atom)
│   └── MemberMeta (Molecule)
│       ├── DepartmentLabel (Atom)
│       ├── BulletDot (Atom)
│       └── LevelBadge (Molecule — "Legend Hero" etc.)
├── IconCollection (Organism)                         # mms_2 — anchor: .badges
│   ├── CollectionTitle "Bộ sưu tập icon của tôi"
│   └── BadgeGrid (Molecule, N items)
│       └── BadgeCell ×N
├── StatsDashboard (Organism)                         # mms_D.1
│   ├── StatPill ×3 (kudos received / sent / hearts)
│   ├── Divider
│   ├── StatPill ×2 (secret boxes opened / unopened)
│   └── PrimaryButton "Mở Secret Box"                 # 6885:10386
├── SectionHeader (Molecule, shared)                  # mms_4 (same as Home's)
├── KudosFilter (Molecule)                            # mms_dropdown
│   ├── SelectedLabel "Đã gửi (5)" / "Đã nhận (5)"
│   └── ChevronIcon
├── KudosList (Organism)                              # mms_5_kudos list
│   └── KudoCard ×N (Organism, shared)                # mms_5.1–5.3 (reusable)
│       ├── TransferHeader (Molecule)                 # sender → receiver
│       ├── Divider
│       ├── KudoBody (Molecule)
│       │   ├── PostedAt (Atom)
│       │   ├── AwardTitleHashtag (Atom)              # e.g. "IDOL GIỚI TRẺ"
│       │   ├── BodyText (Atom)
│       │   ├── PhotoStrip (Molecule, up to 4)        # mm_media_Image ×N
│       │   └── HashtagsList (Atom)
│       ├── Divider
│       └── KudoActions (Molecule)
│           ├── HeartCounter + HeartIcon (Atom)
│           └── ActionButtons (×2)                    # edit/delete for owner, TBC
│       └── StatusOverlay (Atom, optional)            # mms_D.3.1 "Spam" badge
└── BottomTabBar (shared)                             # mms_6_nav bar
```

### Main Components

| Component | Type | Node ID | Description | Reusable |
|-----------|------|---------|-------------|----------|
| `HomeHeader` | Organism | `6885:10338` | Same header shared with Home | **Yes — shared** (as declared in home.md) |
| `MemberBlock` | Organism | `6885:10339` | Identity card (avatar + name + dept + level) | **Yes** — will also appear in `[iOS] Profile người khác` |
| `LevelBadge` | Molecule | `6885:10348` | Renders one or more level titles (e.g. Legend Hero, Rising Hero, Super Hero, New Hero) | **Yes** |
| `BadgeGrid` + `BadgeCell` | Molecule / Atom | `6885:10350-10356` | User's collected badges | **Yes** (same atoms appear in other screens' badge references) |
| `StatsDashboard` + `StatPill` | Organism / Molecule | `6885:10358` | Numeric stat with label | No (Profile-only) |
| `KudosFilter` | Molecule | `6885:10388` | 2-option dropdown (Đã nhận / Đã gửi) | **Yes** — similar pattern on Sun*Kudos filters |
| `KudoCard` | Organism | `6885:8462` (component) | Reusable kudo card used across Sun*Kudos cluster too | **Yes — shared across app** |
| `StatusOverlay` (Spam) | Atom | `6885:10393` | Badge shown on flagged kudos | Shared |
| `BottomTabBar` | Organism | `6885:10394` | Shared across all tab-rooted screens | Shared |

---

## Form Fields (If Applicable)

Not applicable for v1 — no editable fields on this screen. Avatar tap is
flagged as potentially an editor entry point, but the design does not
provide an editor frame, so treat as no-op for v1 (log-only).

---

## API Mapping

Backend: **Supabase**.

### On Screen Load / Resume

| Call | Method | Purpose | Response usage |
|------|--------|---------|----------------|
| `supabase.auth.getSession()` | SDK local | Guard | Redirect to Login if invalid |
| `supabase.from("profiles").select("*, department(*), level(*)").eq("user_id", uid).single()` | GET `/rest/v1/profiles` | Member block | Name, department, levels |
| `supabase.from("badges_owned").select("badge_id, badges(*)").eq("user_id", uid)` | GET | Badge collection | Populate `BadgeGrid` |
| `supabase.rpc("profile_stats", { uid })` | POST (stored function) | Stats dashboard | Returns `{ kudos_received, kudos_sent, hearts_received, secret_boxes_opened, secret_boxes_unopened }` |
| `supabase.from("kudos").select(...).eq("sender_id", uid).order("created_at", desc: true).limit(20)` | GET | Default filter "Đã gửi" | Populate kudos list |

### On User Action

| Action | Call | Method | Request | Response |
|--------|------|--------|---------|----------|
| Toggle filter Đã nhận / Đã gửi | Refetch with `recipient_id = uid` **or** `sender_id = uid` | GET | — | Replace kudos list |
| Pull-to-refresh | Re-run all loads | — | — | Update all blocks |
| Scroll to bottom of kudos list | Keyset pagination on `created_at` | GET | — | Append page |
| Tap "Mở Secret Box" | — | navigation | — | Push `[iOS] Open secret box`; no API call here |
| Tap kudo card | (1) Mark-seen side effect if needed; (2) navigate | navigation | — | Push `[iOS] Sun*Kudos_View kudo(id)` |
| Tap heart on a kudo | `supabase.rpc("toggle_heart", { kudo_id })` | POST | `{ kudo_id }` | `{ hearts, is_liked }` — optimistic UI |
| Tap language chip | — | local | — | Present `LanguagePickerSheet` |
| Tap search | — | navigation | — | Push Search Sunner (TBC) |
| Tap bell | — | navigation | — | Push `[iOS] Notifications` |

### Error Handling

| Error | Source | UI action |
|-------|--------|-----------|
| Session expired | Guard | Redirect to Login |
| Profile fetch failed | REST 5xx | Full-screen retry card (identity is load-bearing) |
| Badges fetch failed | REST 5xx | Hide section; do not block other blocks |
| Stats RPC failed | REST 5xx | Show stats block with placeholders and small retry affordance |
| Kudos list failed | REST 5xx | Inline retry row at top of the list |
| Toggle-heart failed | REST | Revert optimistic toggle; subtle toast |

---

## State Management

### Local State (ViewModel — Principle III)

```swift
protocol ProfileMeViewModel {
    // Inputs
    var viewAppeared: PublishRelay<Void> { get }
    var pullToRefresh: PublishRelay<Void> { get }
    var reachedEnd: PublishRelay<Void> { get }
    var filterChanged: PublishRelay<KudosFilter> { get }       // .received | .sent
    var openSecretBoxTapped: PublishRelay<Void> { get }
    var kudoTapped: PublishRelay<KudoID> { get }
    var heartToggled: PublishRelay<KudoID> { get }
    var anchorRequested: PublishRelay<ProfileAnchor> { get }   // .level | .badges — from deep link

    // Outputs
    var identity: Driver<ProfileIdentityVM?> { get }
    var badges: Driver<[BadgeVM]> { get }
    var stats: Driver<ProfileStatsVM?> { get }
    var kudos: Driver<[KudoCardVM]> { get }
    var selectedFilter: Driver<KudosFilter> { get }
    var isLoading: Driver<Bool> { get }
    var isPaginating: Driver<Bool> { get }
    var navigate: Signal<AppRoute> { get }
    var scrollTo: Signal<ProfileAnchor> { get }
    var errorToast: Signal<String> { get }
}
```

`selectedFilter` defaults to `.received` when the screen is a fresh tab
root; when navigated to via `app://profile/me?filter=sent`, preserve the
deep-link choice.

### Global State

| State | Store | R/W | Purpose |
|-------|-------|-----|---------|
| `AuthState` | `AuthStore` | R | Guard |
| `UnreadNotificationCount` | `NotificationStore` | R | Bell dot in the shared header |
| `CurrentUser` | `AuthStore` | R | `uid` for queries |
| `AppTab` | `TabRouter` | W | This screen asserts `selectedTab == .profile` |

---

## UI States

### Loading State

- Identity, badges, stats, and kudos list each show skeleton placeholders
  independently (render progressively).
- Pull-to-refresh: system indicator on the outer `ScrollView`.

### Error State

- Identity failure is load-bearing (full-screen retry card).
- Other blocks degrade independently — see `Error Handling` table above.

### Success State

- All four blocks populated; heart toggles animate; `Mở Secret Box`
  primary button respects the unopened count (disable at 0 with a hint
  `"Không có secret box để mở"`).

### Empty State

- **Kudos received (empty)**: friendly copy + CTA "Gửi Kudos đầu tiên" →
  navigates to `[iOS] Sun*Kudos_Gửi lời chúc Kudos`.
- **Kudos sent (empty)**: same CTA.
- **Badges empty**: friendly copy "Chưa có huy hiệu. Tham gia hoạt động
  SAA để sưu tập!".
- **Secret boxes unopened = 0**: primary button disabled with the hint
  above.

---

## Accessibility (Principle II)

| Requirement | Implementation |
|-------------|----------------|
| VoiceOver — identity | Composite: `"\(name), \(department), hạng \(level)"` read on appear |
| VoiceOver — stat pill | `"\(n) \(label)"` — e.g. `"5 Kudos nhận được"` |
| VoiceOver — Open Secret Box | `.isButton`; hint: `"Mở một Secret Box mới"` |
| VoiceOver — filter dropdown | `.isButton`; announces current filter + count |
| VoiceOver — kudo card | Composite label; action buttons exposed as separate accessibility elements |
| Dynamic Type | All labels to AX5; StatPill grid collapses to vertical at AX3+ |
| Touch targets | Heart ≥ 44×44; stat pills ≥ 44 tall; badge cells ≥ 44×44 |
| Focus order | Header → Identity → Badges → Stats + CTA → Filter → Kudos list → Tab bar |
| Reduced motion | Disable heart burst animation; use opacity fade |
| Colour contrast | All numeric stats (large digits) ≥ 4.5:1 against background |
| Localisation | VN + EN keys for every label; numbers localised via `NumberFormatter` |

---

## Responsive Behavior

| Device class | Layout |
|--------------|--------|
| iPhone portrait | As designed |
| iPhone landscape | StatsDashboard pills wrap; kudos list unchanged |
| iPad | Max width 600 pt, centered |
| AX3+ | StatPill row → single column; BadgeGrid flows more rows |

---

## Analytics Events (Optional)

| Event | Trigger | Properties |
|-------|---------|------------|
| `profile_me.viewed` | On appear | `{ anchor }` when arriving from a notification deep link |
| `profile_me.refresh` | Pull-to-refresh | — |
| `profile_me.filter_changed` | Filter dropdown | `{ from, to }` |
| `profile_me.open_secret_box_tap` | CTA tap | `{ unopened_count_bucket }` |
| `profile_me.kudo_tap` | Kudo card tap | `{ filter, is_own }` |
| `profile_me.heart_toggled` | Heart tap | `{ new_state }` |

Principle V: never log the user's full name or Sunner names — types and
counts only.

---

## Design Tokens

| Token | Usage |
|-------|-------|
| `Color("TextPrimary")` | Name, body text |
| `Color("TextSecondary")` | Meta (department, timestamp) |
| `Color("StatHighlight")` | Large numeric stat color |
| `Color("BrandPrimary")` | CTA button bg |
| `Color("HeartActive")` | Heart icon when liked |
| `Color("StatusSpam")` | Spam overlay background |
| Font: `.title2` → name, `.largeTitle` → stat digits, `.caption` → meta, `.headline` → button |
| SF Symbols: `chevron.down` (filter), `heart.fill` / `heart`, `gift.fill` (Mở Secret Box) |

Level-badge visual styles differ per tier (Legend Hero, Super Hero,
Rising Hero, New Hero) — captured during `/momorph.specs`.

---

## Implementation Notes

### Clean Architecture touch-points (Principle I)

- **Presentation**:
  `Presentation/Profile/Views/ProfileMeView.swift`,
  `Presentation/Profile/ViewModels/ProfileMeViewModel.swift`,
  `Presentation/Profile/ViewModels/ProfileMeStateAdapter.swift`,
  `Presentation/Profile/Components/MemberBlockView.swift`,
  `Presentation/Profile/Components/BadgeGridView.swift`,
  `Presentation/Profile/Components/StatsDashboardView.swift`,
  `Presentation/Profile/Components/KudosFilterView.swift`,
  `Presentation/Shared/Components/KudoCardView.swift` (shared — introduced here),
  `Presentation/Shared/Components/LevelBadgeView.swift` (shared).
- **Domain**:
  `Domain/UseCases/FetchProfileIdentityUseCase.swift`,
  `Domain/UseCases/FetchBadgeCollectionUseCase.swift`,
  `Domain/UseCases/FetchProfileStatsUseCase.swift`,
  `Domain/UseCases/FetchKudosByUserUseCase.swift` (with `filter: .received | .sent`),
  `Domain/UseCases/ToggleHeartUseCase.swift` (shared),
  `Domain/Entities/Profile.swift`, `Badge.swift`, `ProfileStats.swift`,
  `KudoCard.swift`, `Level.swift`.
- **Data**:
  `Data/Repositories/ProfileRepositoryImpl.swift`,
  `Data/Repositories/BadgeRepositoryImpl.swift`,
  `Data/Repositories/KudoRepositoryImpl.swift` (shared with Sun*Kudos screens),
  `Data/Remote/Profile/*`, `Data/Remote/Badges/*`, `Data/Remote/Kudos/*`.

### Reactive model (Principle III)

- **Parallel initial load**: combine four `Single`s (identity + badges +
  stats + first kudos page) into `Observable.zip` so a single render
  happens when all arrive, OR render progressively using separate
  `BehaviorRelay`s per block (progressive is recommended for better UX).
- **Filter change**:
  ```swift
  filterChanged
      .do(onNext: { [bag] _ in pagingState.reset() })
      .flatMapLatest { filter in repo.fetchKudos(by: uid, filter: filter).asObservable() }
      .bind(to: kudosRelay)
      .disposed(by: bag)
  ```
- **Anchor scroll**: `anchorRequested` is fired once post-initial-load
  (after identity block laid out) — drives a `ScrollViewReader.scrollTo(anchor, anchor: .top)`.

### Security (Principle V)

- RLS policies required (confirm during `/momorph.database`):
  - `profiles`: `SELECT using (true)` OR `using (auth.uid() is not null)` — profiles are visible to all authenticated users.
  - `badges_owned`: `SELECT using (auth.uid() is not null)`.
  - `profile_stats(uid)` RPC: SECURITY DEFINER; internal checks `uid = auth.uid()` OR allow read for any authenticated user if stats are public.
  - `kudos`: `SELECT using (auth.uid() is not null AND status != 'soft_hidden')` — plus owner-visible own soft-hidden kudos; details to finalise.
- No service-role key in client; no raw SQL concatenation (Principle V).
- Do not log `uid`, names, or kudo contents.

### Edge cases

- User has multiple level titles (design shows both "Legend Hero" and
  "Rising Hero") → `LevelBadge` must render a **list**, not a single
  title; order by tier descending.
- User has > 6 badges → `BadgeGrid` wraps to multiple rows; mark-all
  clipped badges as accessible.
- Kudos list switches filter rapidly → `flatMapLatest` cancels prior
  request; no stale race results.
- Kudo is flagged "Spam" mid-view (via Realtime) → render `StatusOverlay`
  overlay without removing the card.
- "Mở Secret Box" CTA when unopened count = 0 → disabled with hint.

---

## Analysis Metadata

| Property | Value |
|----------|-------|
| Analyzed By | `/momorph.screenflow` |
| Analysis Date | 2026-04-24 |
| Source | `get_overview` on `hSH7L8doXB` (depth 5) |
| Needs Deep Analysis | Partial — Kudo card action-button semantics (`Buttons` frame with 2 children) need clarity during `/momorph.specs` |
| Confidence Score | High overall; Medium for exact kudo-card action buttons and avatar-tap behaviour |

### Next Steps

- [ ] Confirm kudo-card action buttons (edit / delete / share / report?) —
      resolve during `/momorph.specs 9ypp4enmFmdK3YAFJLIu6C hSH7L8doXB`
      or during View Kudo analysis.
- [ ] Confirm avatar tap behaviour (editor vs. no-op) with product.
- [ ] Confirm `profile_stats(uid)` as RPC vs. multiple direct queries
      during `/momorph.database`.
- [ ] Clarify visibility rules for Kudos list with status = `soft_hidden`
      or `spam` — likely owner-visible only.
- [ ] Level taxonomy (New Hero → Rising Hero → Super Hero → Legend Hero) —
      model as DB enum or separate `levels` table.
- [ ] Implement `MemberBlock`, `LevelBadge`, `KudoCard` as **shared**
      components in `Presentation/Shared/` during `[iOS] Profile người khác`
      analysis — they will be consumed there with tweaked affordances.
