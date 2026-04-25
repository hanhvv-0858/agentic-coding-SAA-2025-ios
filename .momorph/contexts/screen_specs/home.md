# Screen: [iOS] Home

## Screen Info

| Property | Value |
|----------|-------|
| **Figma Frame ID** | `OuH1BUTYT0` (node `6885:8978`) |
| **Figma Link** | https://momorph.ai/files/9ypp4enmFmdK3YAFJLIu6C/screens/OuH1BUTYT0 |
| **Screen Group** | Core App |
| **Platform** | iOS (SwiftUI) |
| **Status** | discovered |
| **Discovered At** | 2026-04-24 |
| **Last Updated** | 2026-04-24 |

---

## Description

`[iOS] Home` is the **root tab of the authenticated app** and the `SAA 2025`
tab of the bottom Tab Bar. It is the marketing/brand landing that tells
Sunners about the Sun\* Annual Awards 2025 event and the new Sun\*Kudos
programme, with:

- A **countdown** to event day (26/12/2025 at Âu Cơ Art Center), live-streamed
  on "Group Facebook Sun\* Family".
- Two hero CTAs: `ABOUT AWARD` and `ABOUT KUDOS` — both scroll-to-section
  / deep-navigate.
- A horizontal **awards teaser** (Top Talent, Top Project, Top Project Leader
  — each with a `Chi tiết` button opening the award detail screen).
- A **Sun\*Kudos section** with a summary card and a `Chi tiết` CTA into
  Kudos feed.
- A **floating action button (FAB)** combining a pen icon + Kudos logo — the
  entry point to write a Kudos.
- A top header with brand logo, **language chip** (VN by default), **search**
  icon, and **notification bell with unread dot**.
- A **bottom Tab Bar** with 4 tabs: `SAA 2025`, `Awards`, `Kudos`, `Profile`.

---

## Navigation Analysis

### Incoming Navigations (From)

| Source | Trigger | Condition |
|--------|---------|-----------|
| `[iOS] Login` | Post-OAuth success + email domain allowlist pass | Set as navigation root |
| App launch | Auto | Valid Supabase session present in Keychain |
| Any deep link | Post-auth replay | After Login succeeds |

### Outgoing Navigations (To)

| Target | Trigger | Node ID | Confidence | Notes |
|--------|---------|---------|------------|-------|
| `[iOS] Language dropdown` (uUvW6Qm1ve) | Tap language chip | `I6885:9057;88:1829` | High | Modal sheet — see Sub-sheets below |
| `[iOS] Sun*Kudos_Search Sunner` (`3jgwke3E8O`) | Tap search icon | `I6885:9057;88:1869` | Medium | Search scope TBC — could be global or Sunner-only |
| `[iOS] Notifications` (`_b68CBWKl5`) | Tap notification bell | `I6885:9057;88:1830` | High | Bell has unread-dot badge |
| Scroll to `mms_4_awards` section | Tap `ABOUT AWARD` | `6885:9026` | High | Same-screen scroll (anchor link) |
| Scroll to `mms_5_kudos` section | Tap `ABOUT KUDOS` | `6885:9027` | High | Same-screen scroll |
| `[iOS] Award_Top talent` (`c-QM3_zjkG`) | Tap `Chi tiết` on Top Talent card | `6885:9033` | High | — |
| `[iOS] Award_Top project` (`FQoJZLkG_d`) | Tap `Chi tiết` on Top Project card | `6885:9034` | High | — |
| `[iOS] Award_Top project leader` (`QQvsfK3yaK`) | Tap `Chi tiết` on Top Project Leader card | `6885:9035` | High | — |
| `[iOS] Sun*Kudos` (`fO0Kt19sZZ`) | Tap `Chi tiết` under Kudos section | `6885:9055` | High | Opens Kudos feed |
| `[iOS] Sun*Kudos_Gửi lời chúc Kudos` (`PV7jBVZU1N`) | Tap FAB | `6885:9058` | High | Pen + Kudos logo = write-kudo CTA |
| Tab: `SAA 2025` | Tap tab | `I6885:9056;75:2009` | High | Current tab — no-op / scroll-to-top |
| Tab: `Awards` (TBC) | Tap tab | `I6885:9056;75:2012` | Medium | Destination screen not yet in scope — may be a dedicated awards list, TBC during Award cluster analysis |
| Tab: `Kudos` → `[iOS] Sun*Kudos` | Tap tab | `I6885:9056;75:2015` | High | — |
| Tab: `Profile` → `[iOS] Profile bản thân` | Tap tab | `I6885:9056;75:2018` | High | Current user's profile |

### Navigation Rules

- **Back behavior**: Tab root — no back gesture; swiping between tabs is disabled (use Tab Bar).
- **Auth required**: **Yes**. If session is missing/expired on appear, redirect to `[iOS] Login`.
- **Deep link support**: `app://home` lands here (default post-auth). Section anchors (`#awards`, `#kudos`) supported.
- **Pull-to-refresh**: Yes — refreshes awards teaser list, countdown delta, notification badge, kudos highlight.

---

## Component Schema

### Layout Structure

```
┌─────────────────────────────────────┐
│ StatusBar                            │
├─────────────────────────────────────┤
│ [Logo]  [🇻🇳 VN ▾] [🔍] [🔔•]        │ ← mms_1_header
├─────────────────────────────────────┤
│                                      │
│         [RootFuther logo]            │ ← mms_2.1
│                                      │
│         Coming soon                  │
│       [DD] [HH] [MM]                 │ ← countdown
│                                      │
│  Thời gian: 26/12/2025               │
│  Địa điểm: Âu Cơ Art Center          │
│  Tường thuật trực tiếp tại ...       │
│                                      │
│  [ABOUT AWARD]  [ABOUT KUDOS]        │ ← mms_2.2 / 2.3
├─────────────────────────────────────┤
│ "Root Further" — mms_3_note          │
├─────────────────────────────────────┤
│ Sun* Annual Awards 2025              │ ← mms_4_awards header
│ ┌──────┐ ┌──────┐ ┌──────┐           │
│ │ Top  │ │ Top  │ │ Top  │           │ ← horizontal scroll
│ │Talent│ │Proj. │ │Leader│           │
│ │ ...  │ │ ...  │ │ ...  │           │
│ │[Chi tiết]│…                         │
│ └──────┘ └──────┘ └──────┘           │
├─────────────────────────────────────┤
│ Phong trào ghi nhận — Sun*Kudos      │ ← mms_5_kudos
│ [Kudos banner card]                  │
│ "Điểm mới của SAA 2025 ..."          │
│ [Chi tiết]                           │
├─────────────────────────────────────┤
│                               ┌───┐ │
│                               │ ✎ │ │ ← FAB (mms_6)
│                               └───┘ │
├─────────────────────────────────────┤
│ [SAA] [Awards] [Kudos] [Profile]    │ ← Tab Bar (mms_7)
└─────────────────────────────────────┘
```

### Component Hierarchy

```
HomeScreen (SwiftUI View — tab content)
├── HomeHeader (Organism)                           # mms_1_header
│   ├── StatusBar (Atom — system)
│   ├── BrandLogoSmall (Atom)                       # mm_media_logo
│   └── HeaderActions (Molecule)
│       ├── LanguageSwitcherChip (Molecule)         # language (shared with Login)
│       ├── SearchIconButton (Atom)                 # mm_media_search
│       └── NotificationIconButton (Molecule)       # mm_media_notification
│           └── UnreadDotBadge (Atom)
├── HeroSection (Organism)                          # mms_2_content
│   ├── HeroLogo (Atom)                             # RootFuther logo
│   ├── CountdownTimer (Molecule)                   # countdown time
│   │   ├── ComingSoonLabel (Atom)
│   │   └── CountdownUnits ×3 (Atom)                # days / hours / minutes
│   ├── EventInfoList (Molecule)                    # event info
│   │   ├── TimeRow (Atom)
│   │   ├── PlaceRow (Atom)
│   │   └── LiveStreamRow (Atom)
│   └── HeroCTARow (Molecule)                       # actions
│       ├── AboutAwardButton (Atom)                 # mms_2.2 primary
│       └── AboutKudosButton (Atom)                 # mms_2.3 secondary
├── RootFurtherNote (Atom)                          # mms_3_note (paragraph)
├── AwardsTeaser (Organism)                         # mms_4_awards
│   ├── SectionHeader (Molecule)                    # mms_4.1
│   │   ├── Title "Sun* Annual Awards 2025"
│   │   └── Subtitle "Hệ thống giải thưởng"
│   └── AwardCardsRow (Molecule)                    # mms_4.2 horizontal
│       └── AwardCard ×N (Molecule)                 # reusable card
│           ├── AwardArtwork (Atom)
│           ├── AwardName (Atom)
│           ├── AwardTagline (Atom)
│           └── DetailButton (Atom)                 # → Award_* screens
├── KudosSection (Organism)                         # mms_5_kudos
│   ├── SectionHeader (Molecule)                    # mms_5.1
│   ├── KudosBanner (Molecule)                      # mms_5.2
│   ├── KudosNote (Atom)                            # note paragraph
│   └── KudosDetailButton (Atom)                    # mms_5.3 → Sun*Kudos
├── WriteKudoFAB (Molecule)                         # mms_6_float button
│   ├── PenIcon (Atom)
│   └── KudosLogoBadge (Atom)
└── BottomTabBar (Organism)                         # mms_7_nav bar (shared)
    └── TabItem ×4 (Molecule): SAA / Awards / Kudos / Profile
```

### Main Components

| Component | Type | Node ID | Description | Reusable |
|-----------|------|---------|-------------|----------|
| `HomeHeader` | Organism | `6885:9057` | Top header with branding + actions | No |
| `LanguageSwitcherChip` | Molecule | `I6885:9057;88:1829` | Same component as Login | **Yes — shared** |
| `NotificationIconButton` | Molecule | `I6885:9057;88:1830` | With `UnreadDotBadge` | Yes (could appear on other screens later) |
| `CountdownTimer` | Molecule | `6885:8986` | Ticks every second; reads target date from config | No |
| `AwardCard` | Molecule | `6885:9033-9035` | Reused 3× on Home; also appears in Awards tab list | **Yes** |
| `WriteKudoFAB` | Molecule | `6885:9058` | Floating above content, above Tab Bar | No (Home-only per design) |
| `BottomTabBar` | Organism | `6885:9056` | App-wide; lives in `Presentation/Shared/Navigation/` | **Yes — shared** |

---

## Sub-sheets

### LanguagePickerSheet — `[iOS] Language dropdown` (uUvW6Qm1ve)

**Type**: modal picker (fold-in).

Opens when the user taps `LanguageSwitcherChip`. This component is shared
with `[iOS] Login`; the detailed spec of its layout, behaviour, and
persistence lives at
[`screen_specs/login.md → Navigation & Implementation notes`](login.md).

On Home, only note:

- **Contents** (from `get_overview` of `uUvW6Qm1ve`): a dropdown list
  `mms_A_Dropdown-List` with exactly two items — `tiếng Việt` (selected
  by default) and `tiếng Anh`. Confirms **v1 languages = `VN` + `EN`**.
- **Presentation on iOS**: use a SwiftUI `.sheet(isPresented:)` anchored
  to the chip, height `~160 pt`, with a top grabber; or a `Menu` if UX
  prefers an inline menu (design shows a sheet-like panel below the header,
  so `.sheet` with `.presentationDetents([.height(180)])` fits best).
- **State**: selection writes to `LocaleStore` (`AppLanguage`). The change
  triggers a re-render of Home via `@AppStorage("appLanguage")` or
  `LocaleStore`'s Rx output.
- **Accessibility**: rows expose `accessibilityLabel("Tiếng Việt")` /
  `accessibilityLabel("Tiếng Anh")`, and the currently-selected row adds
  `accessibilityAddTraits(.isSelected)`.

Do NOT duplicate the full layout here — if behaviour changes, update
`login.md` and Home will pick it up via shared component.

---

## Form Fields (If Applicable)

Not applicable — Home has no editable form fields. The search icon opens a
separate search screen; there is no inline input on Home.

---

## API Mapping

Backend: **Supabase**. Static content (Root Further note, event date &
place) is bundled in the app (not fetched) unless product decides
otherwise. Dynamic content: awards, kudos, notifications.

### On Screen Load / Resume

| Call | Type | Purpose | Response usage |
|------|------|---------|----------------|
| `supabase.auth.getSession()` | SDK local | Guard: is session still valid? | If expired/nil → navigate to `[iOS] Login` |
| `supabase.from("awards").select().limit(3).order("display_order")` | REST GET | Home teaser: first 3 awards by display order | Populates `AwardsTeaser` |
| `supabase.from("kudos_highlights").select().limit(1)` | REST GET | Latest / featured kudo for the banner | Populates `KudosBanner` |
| `supabase.from("notifications").select("id", count: "exact").eq("recipient_id", uid).is("read_at", nil)` | REST HEAD | Unread count for the bell dot | `> 0` → show dot |
| `AppConfig.eventTargetDate` | local | Countdown target | Countdown ticks locally each 1 s |

### On User Action

| Action | Call | Method | Request | Response |
|--------|------|--------|---------|----------|
| Tap language chip | — | local | — | Present `LanguagePickerSheet` |
| Select language | `LocaleStore.setLanguage(.en \| .vn)` | local | — | Re-renders Home; persists via `UserDefaults` |
| Tap search | — | navigation | — | Push `[iOS] Sun*Kudos_Search Sunner` (TBC during Kudos cluster analysis) |
| Tap notification bell | — | navigation | — | Push `[iOS] Notifications` |
| Tap `ABOUT AWARD` | — | local scroll | — | Scroll to `AwardsTeaser` anchor |
| Tap `ABOUT KUDOS` | — | local scroll | — | Scroll to `KudosSection` anchor |
| Tap `Chi tiết` on Award card | — | navigation | — | Push corresponding `[iOS] Award_*` screen with `awardId` |
| Tap `Chi tiết` on Kudos | — | navigation | — | Push `[iOS] Sun*Kudos` |
| Tap FAB | — | navigation | — | Push `[iOS] Sun*Kudos_Gửi lời chúc Kudos` |
| Tap Tab: Awards | — | tab switch | — | Switches `TabRouter.selectedTab = .awards` |
| Tap Tab: Kudos | — | tab switch | — | Switches to Kudos tab root = `[iOS] Sun*Kudos` |
| Tap Tab: Profile | — | tab switch | — | Switches to Profile tab root = `[iOS] Profile bản thân` |
| Pull-to-refresh | Re-run all "On load" queries | — | — | Update visible sections |

### Error Handling

| Error | Source | UI action |
|-------|--------|-----------|
| Session expired | `getSession()` returns nil | Redirect to Login; discard in-memory Home state |
| Awards fetch failed | REST 5xx / network | Show awards section with a compact retry row ("Không tải được — Thử lại") |
| Kudos banner failed | REST 5xx / network | Hide KudosBanner; show skeleton note only (do not block page) |
| Unread count failed | REST error | Suppress dot — no error UI |
| Countdown target missed (event passed) | local | Replace countdown with "Đã diễn ra" / "Ended" label |

---

## State Management

### Local State (ViewModel — Principle III)

```swift
protocol HomeViewModel {
    // Inputs
    var viewAppeared: PublishRelay<Void> { get }
    var pullToRefresh: PublishRelay<Void> { get }
    var languageTapped: PublishRelay<Void> { get }
    var searchTapped: PublishRelay<Void> { get }
    var notificationsTapped: PublishRelay<Void> { get }
    var aboutAwardTapped: PublishRelay<Void> { get }      // scroll anchor
    var aboutKudosTapped: PublishRelay<Void> { get }      // scroll anchor
    var awardCardTapped: PublishRelay<AwardID> { get }
    var kudosDetailTapped: PublishRelay<Void> { get }
    var fabTapped: PublishRelay<Void> { get }
    var tabTapped: PublishRelay<AppTab> { get }

    // Outputs
    var isRefreshing: Driver<Bool> { get }
    var countdown: Driver<CountdownVM> { get }             // ticks each second
    var awards: Driver<[AwardTeaserVM]> { get }
    var kudosBanner: Driver<KudosBannerVM?> { get }
    var hasUnreadNotifications: Driver<Bool> { get }
    var currentLanguage: Driver<AppLanguage> { get }
    var navigate: Signal<AppRoute> { get }
    var presentLanguageSheet: Signal<Void> { get }
    var scrollTo: Signal<HomeAnchor> { get }               // .awards / .kudos
    var errorMessage: Signal<String> { get }
}
```

| State | Type | Initial | Purpose |
|-------|------|---------|---------|
| `countdown` | `CountdownVM` | computed from `eventTargetDate - now` | Ticks every 1 s via `Observable<Int>.interval(1, scheduler: .main)` |
| `awards` | `[AwardTeaserVM]` | `[]` | First 3 awards by display_order |
| `kudosBanner` | `KudosBannerVM?` | `nil` | Optional: hide if load fails |
| `hasUnreadNotifications` | `Bool` | `false` | Drives the bell dot |
| `isRefreshing` | `Bool` | `false` | Pull-to-refresh indicator |

### Global State

| State | Store | R/W | Purpose |
|-------|-------|-----|---------|
| `AuthState` | `AuthStore` | R | Check session; invalidate on expiry |
| `AppLanguage` | `LocaleStore` | R/W | Current language; writes when user selects in sheet |
| `AppTab` | `TabRouter` | W | Active tab (SAA is the root of this view) |
| `UnreadNotificationCount` | `NotificationStore` | R | Shared across screens; realtime-subscribable via Supabase Realtime |

---

## UI States

### Loading State

- Header: always visible (no skeleton).
- Countdown: zero-state `--:--:--` flicker avoided by computing from local
  `eventTargetDate` immediately.
- Awards: 3 skeleton cards (`AwardCardSkeleton`) until fetch completes.
- Kudos banner: skeleton rectangle until fetch completes or hidden on fail.
- Pull-to-refresh: system `ProgressView` at top of `ScrollView`.

### Error State

- **Awards only**: inline row "Không tải được — Thử lại" inside the awards
  section; other sections keep rendering.
- **Kudos banner only**: silent hide.
- **Session expired**: full-screen route change (no error UI).
- **Countdown > event**: section switches to an "Ended" frame (text TBC).

### Success State

- All sections populated; dot shown only when unread count > 0.

### Empty State

- Awards list empty (backend returns 0 rows): show copy "Giải thưởng sẽ
  được công bố sớm" inside the section.
- Kudos banner empty: hide the banner; keep note paragraph + CTA visible.

---

## Accessibility (Principle II)

| Requirement | Implementation |
|-------------|----------------|
| Dynamic Type | All text scales to AX5; award cards use `VStack` + `lineLimit(nil)`; numbers in countdown use `fixedSize(horizontal: false, vertical: true)` to prevent truncation; horizontal `AwardCardsRow` switches to vertical at AX3+. |
| VoiceOver — header | Language chip label: `"Ngôn ngữ hiện tại: Tiếng Việt. Nhấn để đổi."`; notification bell: `"Thông báo. Có \(n) thông báo chưa đọc."` or `"Thông báo. Không có mới."` |
| VoiceOver — countdown | Announced every minute as a live region, not every second (avoids noise). Example: `"Còn 3 tháng 5 ngày đến sự kiện."` |
| VoiceOver — award card | Combined label: `"\(awardName). \(awardTagline). Nhấn để xem chi tiết."` |
| VoiceOver — FAB | `"Viết Kudo"` + hint `"Ghi nhận đồng nghiệp"` |
| Touch targets | Header icons wrapped in 44×44 pt tap area; Tab items ≥ 56 pt each |
| Focus order | Header (logo → language → search → bell) → Hero CTAs → Awards cards → Kudos CTA → FAB → Tab bar |
| Reduced motion | Disable countdown flip animation; fade instead |
| Colour contrast | All text on hero BG verified ≥ 4.5:1 in both Light and Dark |

---

## Responsive Behavior

| Device class | Layout |
|--------------|--------|
| iPhone portrait | As designed |
| iPhone landscape | Hero + countdown compress; awards row remains horizontal-scroll; FAB moves to trailing safe-area |
| iPad | Max width 600 pt, centered; awards row expands to show all 3 fully |
| AX Sizes (AX3+) | Awards row reflows to vertical; hero CTAs stack |

---

## Analytics Events (Optional)

| Event | Trigger | Properties |
|-------|---------|------------|
| `home.viewed` | On appear | `{ locale, unread_count_bucket }` *(0, 1–5, 6+)* |
| `home.refresh` | Pull-to-refresh | — |
| `home.cta_about_award` | CTA tap | — |
| `home.cta_about_kudos` | CTA tap | — |
| `home.award_card_tap` | Award card tap | `{ award_id }` |
| `home.notification_open` | Bell tap | `{ unread_count_bucket }` |
| `home.fab_tap` | FAB tap | — |
| `home.tab_switch` | Tab tap | `{ from, to }` |
| `home.language_changed` | Sheet selection | `{ from, to }` |

Never log full user email or Supabase token (Principle V).

---

## Design Tokens (to confirm at implementation time)

| Token | Usage |
|-------|-------|
| `Color("BrandPrimary")` | FAB background; primary CTA `ABOUT AWARD` |
| `Color("BrandSecondary")` | Secondary CTA `ABOUT KUDOS`; Kudos section accent |
| `Color("AwardCardBG")` | Award card background (per-award variant possible) |
| `Color("DotBadge")` | Notification unread dot (high-contrast red) |
| Font: `.largeTitle` → Hero title, `.title3` → Section titles, `.headline` → Award names, `.caption` → countdown unit labels |
| SF Symbols: `magnifyingglass`, `bell.fill`, `chevron.down`, `pencil` |

---

## Implementation Notes

### Clean Architecture touch-points (Principle I)

- **Presentation**: `Presentation/Home/Views/HomeView.swift`,
  `Presentation/Home/ViewModels/HomeViewModel.swift`,
  `Presentation/Home/ViewModels/HomeStateAdapter.swift`,
  `Presentation/Home/Components/CountdownTimerView.swift`,
  `Presentation/Home/Components/AwardCardView.swift`,
  `Presentation/Shared/Navigation/BottomTabBarView.swift`,
  `Presentation/Shared/Navigation/AppTab.swift`,
  `Presentation/Shared/Components/LanguageSwitcherChip.swift`,
  `Presentation/Shared/Components/LanguagePickerSheet.swift`.
- **Domain**: `Domain/UseCases/FetchHomeFeedUseCase.swift`
  (aggregates awards teaser + kudos banner + unread count),
  `Domain/UseCases/ObserveUnreadNotificationsUseCase.swift`
  (subscribes to Supabase Realtime),
  `Domain/Entities/AwardTeaser.swift`, `Domain/Entities/KudosHighlight.swift`,
  `Domain/Entities/EventSchedule.swift`.
- **Data**: `Data/Repositories/AwardRepositoryImpl.swift`,
  `Data/Repositories/KudosRepositoryImpl.swift`,
  `Data/Repositories/NotificationRepositoryImpl.swift`,
  `Data/Remote/Awards/AwardRemoteDataSource.swift`,
  `Data/Remote/Kudos/KudosRemoteDataSource.swift`,
  `Data/Remote/Notifications/NotificationRemoteDataSource.swift`.
- **Core**: `Core/Config/AppConfig.swift` (holds `eventTargetDate`,
  `eventPlace`, `liveStreamUrl`, `allowedEmailDomains`).

### Reactive model (Principle III)

- **Countdown**: `Observable<TimeInterval>` from
  `Observable<Int>.interval(.seconds(1), scheduler: MainScheduler.instance)
   .map { _ in eventTargetDate.timeIntervalSinceNow }`. Disposed when the
  screen disappears.
- **Unread badge**: Supabase Realtime channel on `notifications` table
  (`recipient_id = auth.uid()`) → `Observable<Bool>` via `BehaviorRelay`.
- **Pull-to-refresh**: `pullToRefresh → flatMapLatest { fetchHomeFeed() }`,
  with `isRefreshing` toggled by `do(onSubscribe:)` / `onDispose:`.

### Security (Principle V)

- Every query hit by this screen MUST be RLS-protected.
  - `notifications`: policy `using (recipient_id = auth.uid())`.
  - `awards`: public read is acceptable IF design confirms awards are public;
    otherwise policy `using (auth.uid() is not null)` — to verify during
    `/momorph.database`.
  - `kudos_highlights`: likely `using (auth.uid() is not null)` since only
    authenticated users see it.
- The notification count MUST use `count: "exact"` with `head: true` — do
  not download rows client-side just to count them (leaks content).
- Realtime subscription scoped to the user's own channel; server-side
  Realtime RLS must replicate the same policies.

### Edge cases

- User signs out from Profile tab → Home tab root is torn down; AuthStore
  reset; NavigationStack popped to Login.
- Background fetch / app foregrounded after days → countdown may have
  "passed"; transition to the "Ended" state.
- Supabase Realtime disconnected → fallback to a 30-second polling relay;
  both share the same `ObserveUnreadNotificationsUseCase` output.
- Language toggled to EN while on Home → strings refresh immediately; no
  network call needed (bundled strings).

---

## Analysis Metadata

| Property | Value |
|----------|-------|
| Analyzed By | `/momorph.screenflow` |
| Analysis Date | 2026-04-24 |
| Source | `get_overview` on `OuH1BUTYT0` (depth 5) + `uUvW6Qm1ve` (depth 3, fold-in) |
| Needs Deep Analysis | Partial — the `Awards` tab destination and the Search destination need confirmation in later waves |
| Confidence Score | High for own content; Medium for Search / Awards-tab destinations |

### Next Steps

- [ ] Confirm Search destination (Wave 5 — Sun*Kudos cluster).
- [ ] Confirm `Awards` tab destination — possibly a dedicated list screen
      that is not yet mapped, or a filter view of Home. Decide during
      Wave 4 (Awards cluster).
- [ ] Run `/momorph.specs 9ypp4enmFmdK3YAFJLIu6C OuH1BUTYT0` for detailed
      component tokens before implementation.
- [ ] Wire `eventTargetDate`, `eventPlace`, `liveStreamUrl` into
      `AppConfig` / `.xcconfig` with current values (`26/12/2025`,
      `Âu Cơ Art Center`, Facebook Group Sun\* Family URL).
