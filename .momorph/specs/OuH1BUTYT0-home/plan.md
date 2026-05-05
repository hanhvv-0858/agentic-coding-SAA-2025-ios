# Implementation Plan: M2 — Home (SAA 2025 tab) + App shell

**Frame**: `OuH1BUTYT0-home` (`[iOS] Home`)
**Date**: 2026-04-27
**Spec**: [spec.md](spec.md)
**Roadmap**: [IMPLEMENTATION_ROADMAP.md § M2](../../contexts/IMPLEMENTATION_ROADMAP.md)
**Status**: Draft

---

## Summary

Deliver the **authenticated tab-root** of the Sun\* SAA 2025 iOS app:
the `[iOS] Home` screen with a real-time event countdown, an awards
teaser, a Kudos onboarding banner, the floating action button, the
4-tab `BottomTabBar`, and the live-updating notification dot.
Underneath, this milestone introduces the **app shell** every other
M3+ feature consumes: `TabRouter`, `BottomTabBar`, `HomeHeader`,
`UnreadDotBadge`, `AppRoute.awardDetail(kind:)`, the `FetchHomeFeed`
+ `ObserveUnreadNotifications` use cases, and the M2 share of
shared organisms / atoms.

Several of M2's defaults are intentionally **placeholders that bind
to final routes** so M3 / M4 / M5 can swap in the real screens with
**zero nav-contract change** (per spec §Q2 resolution + §Notes "M4
handoff seam"):

- `AppRoute.awardDetail(kind:)` → `AwardDetailPlaceholder` (M2) →
  `AwardDetailView(kind:)` (M4). Awards tab and AwardCard "Chi tiết"
  both feed this route.
- `AppRoute.writeKudo(recipientId:)` → `ComingSoonPlaceholder` (M2,
  variant `compose`) → real composer (M4). FAB pen-zone target.
- `AppRoute.sunKudos` (Kudos feed) → `ComingSoonPlaceholder` (M2,
  variant `kudosFeed`) → real Kudos feed (M4). FAB `S`-zone, Kudos
  tab, and Kudos section "Chi tiết" all feed this route.
- `AppRoute.searchSunner` → `ComingSoonPlaceholder` (M2, variant
  `search`) → real search (M5 / Kudos cluster). Header search icon
  feeds this route.
- `AppRoute.profileMe(anchor:)` → `ComingSoonPlaceholder` (M2,
  variant `profile`) → real Profile (M3). Profile tab feeds this
  route.
- `AppRoute.notifications` → real Notifications inbox (sibling spec,
  also M2 — the inbox lands in parallel; Home only emits the route).
- Bundled Kudos banner asset (M2) → dynamic `kudos_highlights` view
  (M4 — per spec Q7).

`AppRoute` already declares all of the above cases (in
[AppRoute.swift](../../../AIDD-SAA-2025/Presentation/Shared/Navigation/AppRoute.swift)
from the M0 nav scaffolding). The only signature change M2 makes is
**re-typing `awardDetail(kind: String)` → `awardDetail(kind: AwardKind)`**
so the placeholder + future real view can pattern-match on the typed
enum. There is no new `AppRoute` case in M2.

Because Home is the first authenticated-tab screen, this milestone
also extracts and ships shared infrastructure that the rest of the
app reuses: the Tab router, the bottom tab bar, the home header, and
the notification dot.

---

## Technical Context

| | |
|---|---|
| **Language/Framework** | Swift 5.9+ / SwiftUI (iOS 17+, deployment target ratified in M0) |
| **Primary deps** | `RxSwift 6.10.2` (`RxSwift`, `RxRelay`, `RxCocoa`, `RxBlocking`, `RxTest`), `supabase-swift 2.44.1` (`Supabase` product). **No new SPM packages added in M2** — `Package.resolved` MUST stay byte-identical with M1. |
| **System frameworks** | `Foundation`, `SwiftUI`, `Combine` (only at SwiftUI bridge), `os.Logger`, `UIKit` (notification names only — no UIView usage) |
| **Backend** | Supabase. Tables: `public.awards` (read), `public.notifications` (head-count + Realtime). No new tables in M2 — schema migrations 0024 (notifications) + 0025 (awards) are already applied. |
| **Reactive model** | RxSwift across layer boundaries; Swift Concurrency only inside data sources to bridge `async`/`AsyncSequence` (Realtime channel) into `Observable`/`Single`. |
| **Testing** | XCTest + RxTest/RxBlocking (unit + Rx ViewModel); XCUITest (cold-launch shows countdown + bell — Q2-resolution placeholder reachable). |
| **Architecture** | Clean Architecture: `Presentation → Domain ← Data`; `nonisolated` default actor isolation per Constitution III amendment (post-M1). |
| **Feature-specific deviations** | None planned. Open Questions Q3 / Q6 / Q7 from spec do NOT block planning — they affect FAB simplification / asset-prep / Kudos-banner-source tasks within M2 but not the architecture. (Q1 + Q2 + Q5 all resolved 2026-04-27.) |

---

## Constitution Compliance Check

*GATE — must pass before merge.*

- [x] **I. Clean Architecture** — `Presentation/Home/*` depends on `Domain/UseCases/*` only via protocols. Domain has no Supabase / Rx-Cocoa imports. Data layer is the only place `import Supabase` exists. The new `TabRouter` lives in `Domain/Stores/` and is consumed by `Presentation/Shared/Navigation/`.
- [x] **II. SwiftUI-First & HIG** — `HomeView`, `HomeHeader`, `BottomTabBar`, `AwardDetailPlaceholder` built in SwiftUI; Dynamic Type AX5; localised strings via `Localizable.xcstrings`; HIG-minimum touch targets; VoiceOver labels per spec §Behavioral Requirements; Reduced-Motion gate on countdown digit transitions. **`design-style.md` is authored INLINE during M2** (process amendment for this milestone — see §Visual Parity Strategy below): each US phase ends with a Visual-Parity task that fetches Figma tokens for that phase's components via `query_section` / `get_node_context` / `list_frame_styles` and appends a section to `design-style.md`. The document grows alongside implementation, not after — this prevents the M1-Login class of bug where deferred visual fidelity led to icons / images / gradients silently missing at merge.
- [x] **III. Reactive Data Flow with RxSwift** — `HomeViewModel` exposes `Driver`/`Signal` outputs only; countdown via `Observable<Int>.interval(.seconds(1), MainScheduler.instance)`; unread-count via Supabase Realtime → `BehaviorRelay`; pull-to-refresh via `flatMapLatest`. `subscribe(on:)` / `observe(on:)` set explicitly at SDK boundaries. **Default actor isolation = `nonisolated`** (M1 amendment) — every new class in Domain / Data / Core picks it up automatically; SwiftUI bridges are `@MainActor` via `@StateObject` / `@Published`.
- [x] **IV. Test-First** — RxTest scenarios for every US AS are written **before** the corresponding ViewModel impl (Red → Green → Refactor). `AwardRepositoryImplTests` + `NotificationRepositoryImplTests` cover happy / 5xx / RLS-denied / Realtime-emit ordering. XCUITest cold-launch + countdown + tab-switch is a merge gate. **Validation cadence** follows the [Constitution §Development Workflow](../../constitution.md#development-workflow--quality-gates) rule (2026-04-27, amended same day): `xcodebuild build-for-testing` after each task / batch (compile-only, ~15 s); optional targeted subset (`-only-testing:<NewSuite>`) at phase boundaries; **full `xcodebuild test` only at end-of-screen, end-of-cluster, or on explicit user request**. CI gates unchanged.
- [x] **V. Secure-by-Default** — `notifications` query uses `count: "exact"` + `head: true` so we never download row contents to count them. Realtime channel filtered to `recipient_id=eq.${auth.uid()}`; server-side Realtime RLS replicates the SELECT policy on `public.notifications`. No PII in logs (`.private` interpolation for any `recipient_id` / `kudo.id`). Analytics carry `unread_count_bucket` (`0` / `1-5` / `6+`) only — never raw count.

**Violations**: none.

---

## Architecture Decisions

### Presentation Layer (SwiftUI + RxSwift)

**New screens / placeholders**

| Screen | View | ViewModel | StateAdapter | Route |
|---|---|---|---|---|
| Home | `HomeView` | `HomeViewModel` | `HomeStateAdapter` | `.home` |
| Award detail (M2 placeholder) | `AwardDetailPlaceholder` | (none — re-uses `ErrorStateView` pattern; consumes `awards.placeholder.*` strings) | n/a | `.awardDetail(kind:)` |
| Compose Kudo / Kudos feed / Search Sunner / Profile (M2 placeholders) | `ComingSoonPlaceholder(variant:)` (single view; renders localised title + back button + `ErrorStateView`) | (none) | n/a | `.writeKudo` / `.sunKudos` / `.allKudos` / `.searchSunner` / `.profileMe` |

Notifications inbox + Notifications row views are **scoped to the
sibling Notifications spec** (also M2) and are not re-described here.

**ViewModel contracts** — locked from spec:

- `HomeViewModel`: signature in [spec.md § State Management](spec.md#state-management).
  Notable inputs added vs spec template: `fabComposeTapped`,
  `fabKudosFeedTapped` (per Q3-default of 2 tap zones),
  `activeTabReTapped` (idiomatic SAA-tap-while-active scroll-to-top).
  Outputs: per-section state enums (`AwardsTeaserState`,
  `KudosBannerState`), `Signal<AppRoute>` for navigation,
  `Signal<HomeAnchor>` for same-screen scroll, `Driver<Bool>` for
  the bell dot, `Driver<CountdownVM>` for the countdown.

**Navigation** — extends M1's `AppRouter`:

- `AppTab` already exists from M1 (`saa` / `awards` / `kudos` /
  `profile`). New: a `TabRouter` (Domain store) that owns
  `selectedTab: BehaviorRelay<AppTab>`. M2 introduces it; later
  features consume the same store.
- `AppRoute` is **not extended with new cases** in M2 — every route
  the FAB / search / tab bar / award cards push (`awardDetail`,
  `writeKudo`, `sunKudos`, `searchSunner`, `profileMe`,
  `notifications`) already exists in
  [`AppRoute.swift`](../../../AIDD-SAA-2025/Presentation/Shared/Navigation/AppRoute.swift)
  from the M0 scaffolding. M2 only **re-types** `awardDetail(kind:
  String)` → `awardDetail(kind: AwardKind)` so the placeholder and
  the M4 real view share a typed payload. (Hashable still satisfied
  via `AwardKind: Hashable`; the only consumer today is `RootView`'s
  default branch — no compile breakage downstream.)
- `RootView`'s switch grows to handle `.home` (real Home),
  `.awardDetail(kind:)` (`AwardDetailPlaceholder`), `.writeKudo`,
  `.sunKudos`, `.allKudos`, `.searchSunner`, `.profileMe`
  (`ComingSoonPlaceholder` variants), and to mount the bottom tab
  bar via `safeAreaInset(.bottom)`. The `default` fall-through to
  `LoginView` is removed — every `AppRoute` case must resolve to a
  concrete view (placeholder or real) in M2.

**Shared components introduced this milestone** (re-used by ≥3 future
screens or required app-wide):

- `BottomTabBar` (organism, app-wide). Lives in
  `Presentation/Shared/Navigation/`. Owns 4 `AppTab` items;
  publishes `tabTapped: Signal<AppTab>` and
  `activeTabReTapped: Signal<Void>`.
- `HomeHeader` (organism — Home-only, but re-uses M1 atoms).
- `UnreadDotBadge` (atom, app-wide). Used here on the bell;
  re-used on M3 Profile (avatar dot) and M4 Kudos (per-row dots).
- `CountdownTimerView` (molecule — Home-only).
- `AwardCardView` (molecule — also re-used in M4 Award detail).
- `KudosBannerView` (molecule — Home-only for M2; if Q7 picks
  dynamic source, the molecule absorbs the data binding).
- `WriteKudoFAB` (molecule — Home-only; the only screen that
  shows a FAB in v1).

**HIG / a11y checklist** (per screen)

- `accessibilityLabel` keys defined in `Localizable.xcstrings`
  (see spec §Behavioral Requirements for the 31 keys).
- VoiceOver order asserted explicitly: header → hero → awards →
  kudos → FAB → tab bar.
- Reduce-Motion: countdown digit transitions are static; system
  refresh indicator inherits the OS setting automatically.
- Touch targets: enforce HIG minimum on every tap area; verified
  in XCUITest via `accessibilityFrame.size`.

### Domain Layer

**Use cases (new in M2)**

| Use case | Signature | Replaces |
|---|---|---|
| `FetchHomeFeedUseCase` | `execute() -> Single<HomeFeed>` | n/a — combines awards teaser + kudos banner + initial unread count (single batched call) |
| `ObserveUnreadNotificationsUseCase` | `execute() -> Observable<Int>` | n/a — Supabase Realtime channel → `BehaviorRelay<Int>`; falls back to 30 s polling on disconnect |
| `MarkNotificationReadUseCase` | `execute(id: UUID) -> Completable` | n/a (used by Notifications inbox; defined here so Home + Notifications share the same domain surface) |
| `MarkAllNotificationsReadUseCase` | `execute() -> Completable` | n/a (same) |
| `FetchAwardsUseCase` | `execute() -> Single<[AwardTeaser]>` | n/a — Home calls via `FetchHomeFeed`; a separate use case lets the future Awards tab call it directly |
| `FetchKudosHighlightUseCase` | `execute() -> Single<KudosHighlight?>` | n/a — same pattern; M2 returns a bundled-asset placeholder until Q7 lands the dynamic view |
| `SetActiveTabUseCase` | `execute(_ tab: AppTab)` | n/a — wraps `TabRouter.set` (kept thin for testability + analytics hook) |

**Entities (new in M2)**

```swift
struct HomeFeed: Equatable {
    let awards: [AwardTeaser]
    let kudosBanner: KudosHighlight?
    let unreadNotificationCount: Int
}

enum AwardKind: String, CaseIterable, Codable, Hashable {
    case mvp                = "mvp"
    case bestManager        = "best_manager"
    case signatureCreator   = "signature_creator"
    case topProject         = "top_project"
    case topProjectLeader   = "top_project_leader"
    case topTalent          = "top_talent"
}
// NOTE: revised 2026-04-27 during PR-M2.1 implementation. The DB enum
// in migration 0025 (`award_kind`) is the source of truth and uses these
// 6 cases — the original plan listed `topPerformer` / `topContributor`
// which do not exist. Spec + plan adjusted accordingly.

struct AwardTeaser: Equatable, Identifiable {
    var id: AwardKind { kind }
    let kind: AwardKind
    let titleVI: String
    let titleEN: String
    let descriptionVI: String
    let descriptionEN: String
    let artworkAssetKey: String
    let displayOrder: Int

    func localisedTitle(for lang: AppLanguage) -> String { lang == .vi ? titleVI : titleEN }
    func localisedDescription(for lang: AppLanguage) -> String { lang == .vi ? descriptionVI : descriptionEN }
}

struct KudosHighlight: Equatable, Identifiable {
    let id: UUID
    let bannerImageURL: URL?     // nil for M2 bundled-asset path
}

struct EventSchedule: Equatable {
    let targetDate: Date         // sourced from AppConfig
    let place: String
    let liveStreamURL: URL?
}

struct CountdownVM: Equatable {
    let days: Int
    let hours: Int
    let minutes: Int
    var hasEnded: Bool { days <= 0 && hours <= 0 && minutes <= 0 }
}

enum AwardsTeaserState: Equatable { case loading, loaded([AwardTeaser]), empty, error }
enum KudosBannerState : Equatable { case loading, loaded(KudosHighlight), empty }
enum HomeAnchor       { case top, awards, kudos }
```

**Repository protocols** (Domain)

```swift
protocol AwardRepository: AnyObject {
    func teaser() -> Single<[AwardTeaser]>
    // M4 may add: detail(kind:) -> Single<AwardDetail>
}

protocol KudosHighlightRepository: AnyObject {
    /// M2 returns a bundled-asset placeholder. M4 swaps to a
    /// dynamic view-backed query (Q7).
    func current() -> Single<KudosHighlight?>
}

protocol NotificationRepository: AnyObject {
    func unreadCount() -> Single<Int>
    func observeUnreadCount() -> Observable<Int>      // Realtime + 30 s polling fallback
    func markRead(id: UUID) -> Completable
    func markAllRead() -> Completable
}
```

**New Domain stores**

```swift
protocol TabRouting: AnyObject {
    var selectedTab: BehaviorRelay<AppTab> { get }
    var selectedTabObservable: Observable<AppTab> { get }
    func set(_ tab: AppTab)
}

protocol NotificationStoring: AnyObject {
    var unreadCount: BehaviorRelay<Int> { get }
    var hasUnreadObservable: Observable<Bool> { get }
}
```

**Validation at Domain boundary**

- `AwardKind` is the canonical enum; every DTO mapping into
  `AwardTeaser` MUST validate the `kind` string against
  `AwardKind.allCases` and surface `AwardError.unknownKind` if the
  backend ever ships a 7th category.
- `unreadCount` floor-clamped to `0` (defensive — Supabase
  shouldn't return negative but RLS-denied responses can return
  unexpected NULLs that must coerce to `0`).

### Data Layer (Supabase)

**Tables touched** (read-only):

- `public.awards` — already migrated (0025). M2 adds the read path
  + applies the authenticated-only RLS policy decided in Q5
  (`USING (auth.uid() IS NOT NULL)`) on staging before PR-M2.3.
- `public.notifications` — already migrated (0024). M2 adds:
  - HEAD count read with `head: true` + `count: "exact"`.
  - Realtime subscription on `recipient_id=eq.${auth.uid()}`.
  - Mark-read / mark-all-read writes (used by Notifications inbox).

**Schema changes in M2**: a single RLS-policy migration for
`public.awards` (authenticated-only read per Q5 resolution). No
table / column changes. Q6 (artwork delivery) and Q7 (Kudos
banner source) may add follow-up migrations *later* — neither is
part of M2 ship.

**Files**

- `Data/Repositories/AwardRepositoryImpl.swift` — `Single<[AwardTeaser]>` over `from("awards").select().order("display_order").limit(6)`.
- `Data/Repositories/NotificationRepositoryImpl.swift` — composes the head-count query, the Realtime subscription, the polling fallback, and the mark-read writes.
- `Data/Repositories/KudosHighlightRepositoryImpl.swift` — for M2, returns a `KudosHighlight(id: <bundled UUID>, bannerImageURL: nil)` synchronously; the molecule renders the bundled asset. Q7 lands a real query in M4.
- `Data/Remote/Awards/{AwardRemoteDataSource,AwardDTO}.swift` — DTO maps `awards` row → `AwardTeaser`; never copies `kind` text into logs.
- `Data/Remote/Notifications/{NotificationRemoteDataSource,NotificationDTO}.swift` — DTO maps `notifications` row → `Notification` entity (typed payload by `notification_type`).
- `Data/Local/Notifications/PollingFallback.swift` — drives the 30 s polling relay when the Realtime channel reports `disconnected` / `closed`. Backed by `Observable<Int>.interval` + `withLatestFrom(currentSession)`.

**SDK boundary discipline**

- `subscribe(on: ConcurrentDispatchQueueScheduler.io)` for awards
  GET + notifications HEAD.
- Realtime channel runs on its own SDK-managed queue; the
  observable is bridged via `Observable.create` and explicitly
  hops to `MainScheduler.instance` before reaching the View layer.

### Integration Points

- **Supabase services**: Auth (existing M1 wiring), Postgres (`awards` SELECT, `notifications` HEAD), Realtime (`notifications` channel). Storage + Edge Functions remain unused in M2.
- **Shared infra introduced here, consumed downstream**: `BottomTabBar`, `TabRouter`, `AppTab`, `UnreadDotBadge`, `CountdownTimerView` is Home-only; `AwardCardView` is also used by M4.
- **Secrets**: no new keys. `SUPABASE_URL` / `SUPABASE_ANON_KEY` / `OAUTH_REDIRECT_URL` already wired in M1; M2 adds `EVENT_TARGET_DATE` / `EVENT_PLACE` / `LIVE_STREAM_URL` reads (already populated in `AppConfig` by M0).

---

## Project Structure

### Documentation

```text
.momorph/specs/OuH1BUTYT0-home/
├── spec.md          # ✅ reviewed
├── plan.md          # this file
├── tasks.md         # ✅ generated
└── design-style.md  # incrementally authored — seeded by US1 visual-parity task; appended by every subsequent US phase's parity task (see §Visual Parity Strategy)
```

### Source code (paths to land in M2)

```text
AIDD-SAA-2025/
├── Core/
│   ├── Config/AppConfig.swift                       # ✅ M0 (verify EVENT_* values)
│   ├── DI/Container.swift                           # MODIFY — register award/notification/kudos-highlight repos + new use cases + TabRouter + NotificationStore + Home VM factory
│   └── Logger.swift                                 # ✅ M1 (add `home` + `notifications` categories)
├── Domain/
│   ├── Entities/
│   │   ├── HomeFeed.swift                           # NEW
│   │   ├── AwardKind.swift                          # NEW
│   │   ├── AwardTeaser.swift                        # NEW
│   │   ├── KudosHighlight.swift                     # NEW
│   │   ├── EventSchedule.swift                      # NEW
│   │   ├── CountdownVM.swift                        # NEW
│   │   └── Notification.swift                       # NEW (sibling spec — placed here for cross-feature reuse)
│   ├── Repositories/
│   │   ├── AwardRepository.swift                    # NEW (protocol)
│   │   ├── KudosHighlightRepository.swift           # NEW (protocol)
│   │   └── NotificationRepository.swift             # NEW (protocol)
│   ├── Stores/
│   │   ├── TabRouter.swift                          # NEW
│   │   ├── NotificationStore.swift                  # NEW
│   │   ├── AuthStore.swift                          # ✅ M1
│   │   └── LocaleStore.swift                        # ✅ M1
│   └── UseCases/
│       ├── FetchHomeFeedUseCase.swift               # NEW
│       ├── FetchAwardsUseCase.swift                 # NEW
│       ├── FetchKudosHighlightUseCase.swift         # NEW
│       ├── ObserveUnreadNotificationsUseCase.swift  # NEW
│       ├── MarkNotificationReadUseCase.swift        # NEW
│       ├── MarkAllNotificationsReadUseCase.swift    # NEW
│       └── SetActiveTabUseCase.swift                # NEW
├── Data/
│   ├── Repositories/
│   │   ├── AwardRepositoryImpl.swift                # NEW
│   │   ├── KudosHighlightRepositoryImpl.swift       # NEW (M2: bundled-asset placeholder)
│   │   └── NotificationRepositoryImpl.swift         # NEW
│   ├── Remote/
│   │   ├── Awards/AwardRemoteDataSource.swift       # NEW
│   │   ├── Awards/AwardDTO.swift                    # NEW
│   │   ├── Notifications/NotificationRemoteDataSource.swift  # NEW
│   │   ├── Notifications/NotificationDTO.swift      # NEW
│   │   └── Notifications/RealtimeUnreadChannel.swift # NEW (Realtime → Observable<Int>)
│   └── Local/
│       └── Notifications/PollingFallback.swift      # NEW (30 s relay)
├── Presentation/
│   ├── Shared/
│   │   ├── Navigation/
│   │   │   ├── AppRoute.swift                       # MODIFY — re-type `.awardDetail(kind: String)` → `.awardDetail(kind: AwardKind)` (no new cases)
│   │   │   ├── AppRouter.swift                      # ✅ M1
│   │   │   ├── AppTab.swift                         # ✅ M1
│   │   │   ├── AuthRouterBinder.swift               # ✅ M1
│   │   │   └── BottomTabBar.swift                   # NEW (organism, app-wide)
│   │   └── Components/
│   │       ├── UnreadDotBadge.swift                 # NEW (atom)
│   │       ├── ErrorStateView.swift                 # ✅ M1 (reused by AwardDetailPlaceholder)
│   │       ├── PrimaryButton.swift                  # ✅ M1
│   │       ├── BackIconButton.swift                 # ✅ M1
│   │       ├── TopNavigation.swift                  # ✅ M1
│   │       ├── LanguageSwitcherChip.swift           # ✅ M1
│   │       └── LanguagePickerDropdown.swift         # ✅ M1
│   ├── Home/
│   │   ├── Views/
│   │   │   ├── HomeView.swift                       # NEW
│   │   │   ├── HomeHeader.swift                     # NEW (organism, Home-only)
│   │   │   ├── CountdownTimerView.swift             # NEW (molecule)
│   │   │   ├── AwardCardView.swift                  # NEW (molecule — also used by M4)
│   │   │   ├── KudosBannerView.swift                # NEW (molecule)
│   │   │   ├── WriteKudoFAB.swift                   # NEW (molecule)
│   │   │   └── AwardDetailPlaceholder.swift         # NEW (M2 placeholder; M4 swaps to AwardDetailView)
│   ├── Placeholders/
│   │   └── ComingSoonPlaceholder.swift              # NEW (single view, variant: .compose / .kudosFeed / .search / .profile; M3+M4+M5 swap each variant individually)
│   │   └── ViewModels/
│   │       ├── HomeViewModel.swift                  # NEW (protocol + impl)
│   │       └── HomeStateAdapter.swift               # NEW (Rx → @Published bridge)
│   └── Root/
│       └── RootView.swift                           # MODIFY — exhaustive switch over every `AppRoute` case (real `.home`, `AwardDetailPlaceholder` for `.awardDetail`, `ComingSoonPlaceholder` variants for `.writeKudo` / `.sunKudos` / `.allKudos` / `.searchSunner` / `.profileMe`); mount `BottomTabBar` via `safeAreaInset(.bottom)`; remove the M1 `default → LoginView` fall-through
└── Resources/
    ├── Localizable.xcstrings                        # MODIFY — add ~31 home / awards / tab keys
    └── Assets.xcassets/
        ├── KudosBanner.imageset/                    # NEW (bundled banner per Q7 default)
        ├── awards/                                  # NEW (6 award artworks per Q6 — pending decision)
        └── (existing M1 assets)                     # ✅

AIDD-SAA-2025Tests/
├── Domain/
│   ├── Entities/
│   │   ├── AwardKindTests.swift                     # NEW (raw-value mapping + decoding)
│   │   ├── CountdownVMTests.swift                   # NEW (computation + boundary)
│   │   └── HomeFeedTests.swift                      # NEW (Equatable)
│   └── UseCases/
│       ├── FetchHomeFeedUseCaseTests.swift          # NEW
│       ├── FetchAwardsUseCaseTests.swift            # NEW
│       ├── FetchKudosHighlightUseCaseTests.swift    # NEW
│       ├── ObserveUnreadNotificationsUseCaseTests.swift  # NEW
│       ├── MarkNotificationReadUseCaseTests.swift   # NEW
│       ├── MarkAllNotificationsReadUseCaseTests.swift # NEW
│       └── SetActiveTabUseCaseTests.swift           # NEW
├── Presentation/Home/
│   └── HomeViewModelTests.swift                     # NEW (RxTest TestScheduler)
└── Data/
    ├── Awards/AwardRepositoryImplTests.swift        # NEW
    ├── Notifications/NotificationRepositoryImplTests.swift  # NEW
    └── KudosHighlight/KudosHighlightRepositoryImplTests.swift  # NEW

AIDD-SAA-2025UITests/
└── Home/
    ├── HomeUITests.swift                            # NEW (cold-launch + countdown + tab-switch)
    └── AwardDetailPlaceholderUITests.swift          # NEW (tap card → placeholder is reachable + back works)
```

### Dependencies — none added in M2

`Package.resolved` already pins `RxSwift 6.10.2` + `supabase-swift 2.44.1`. No new SPM packages.

---

## Implementation Strategy

### Vertical-slice ordering

Deliver in this order so each PR is a usable, mergeable increment:

| Phase | PR | What lands | Visible result | Tests |
|---|---|---|---|---|
| **0** | PR-M2.0 | `EVENT_*` xcconfig values verified; `AwardKind` enum; new localisation keys (no `home.event.ended` per Q1 resolution) | App still launches; xcstrings updated; no behaviour change | n/a |
| **1** | PR-M2.1 | Foundation: re-type `AppRoute.awardDetail(kind:)` to `AwardKind`; `TabRouter`; `NotificationStore`; `BottomTabBar` (UI only — no live data); `AwardDetailPlaceholder`; `ComingSoonPlaceholder(variant:)` covering `.compose / .kudosFeed / .search / .profile`; `RootView` switch becomes exhaustive; M1 smoke still passes | After auth, user sees a 4-tab shell; tapping any tab swaps to the right placeholder; tapping an Award card opens the AwardDetailPlaceholder; FAB / search / Profile tab all land on a stable Coming-Soon screen with a working back button | RxTest for `TabRouter`; XCUITest for tab-switch + back; XCUITest asserts every `AppRoute` resolves to a non-Login view |
| **2** | PR-M2.2 (US1 + US3 = MVP) | `EventSchedule`, `CountdownVM`, `CountdownTimerView`, `HomeHeader` (with bell + chip), `UnreadDotBadge`, `NotificationRepositoryImpl` (HEAD count + Realtime), `ObserveUnreadNotificationsUseCase`, `HomeView` shell w/ countdown + bell + chip; `HomeViewModel` outputs `countdown` + `hasUnreadNotifications` | A `@sun-asterisk.com` user signs in → Home shows live countdown + unread bell dot. Awards / Kudos sections are skeleton stubs. | RxTest for VM countdown + bell binding; XCUITest cold-launch shows countdown text + bell dot when seeded notification exists |
| **3** | PR-M2.3 (US2) | `AwardKind` enum (full), `AwardTeaser` entity, `AwardRepositoryImpl`, `FetchAwardsUseCase`, `AwardCardView`, `AwardCardsRow`, `FetchHomeFeedUseCase` (composes awards + kudos-banner + initial unread count); Home renders awards horizontal scroll | The 3-card teaser appears; tapping `Chi tiết` opens `AwardDetailPlaceholder` for the right `kind`. Empty + error states wired. | RxTest for awards state machine; integration test against staging awards table |
| **4** | PR-M2.4 (US4 + US5 + US6 + US7) | `KudosBannerView`, `KudosHighlightRepositoryImpl` (bundled-asset path for M2), `WriteKudoFAB` (2 tap zones per Q3-default), `LanguagePickerDropdown` integration on Home (re-uses M1 component), pull-to-refresh wiring, search icon nav, ABOUT-AWARD/KUDOS scroll anchors | Full Home is interactive; FAB pen → placeholder for compose; FAB `S` → placeholder for Kudos feed; chip swaps language; pull-to-refresh re-fetches | RxTest for the rest of the VM; XCUITest for chip + pull-to-refresh + scroll anchor + FAB tap zones |
| **5** | PR-M2.5 (US8 + Polish) | `BottomTabBar` final wiring (active state + re-tap → scroll-to-top via `activeTabReTapped` signal), all VoiceOver labels, all `analytics.track` calls, error-state copy polished, performance pass against SC-HOME-1..6 | Tab switching feels instant; all SCs measured; zero blocking warnings on `xcodebuild` | RxTest for tab-switch + active-re-tap; XCUITest for the cold-launch happy path + per-section error states |

**Branch naming**: `feat/m2.{0-5}-<short-desc>` per Constitution §Workflow.

### Phase 0 — Setup (PR-M2.0)

1. Verify `Config/{Dev,Staging,Prod}.xcconfig` populate `EVENT_TARGET_DATE`, `EVENT_PLACE`, `LIVE_STREAM_URL` — values current as of 2026-04-27 (event has passed → countdown will clamp to `0 / 0 / 0` immediately on launch and the "Coming soon" label will be hidden, per Q1 resolution).
2. Add the 30 localisation keys from spec §Behavioral Requirements to `Localizable.xcstrings` (VN + EN). No `home.event.ended` key is added (Q1 resolved to clamp at zero with no extra copy).
3. Confirm `Package.resolved` byte-identical with M1 (Constitution §Workflow).

### Phase 1 — Foundation (PR-M2.1)

Land the **shell** before any data work:

1. Re-type `AppRoute.awardDetail(kind: String)` → `AppRoute.awardDetail(kind: AwardKind)`. `AwardKind` is defined as an `enum` with raw values matching `award_kind` in DB; no body validation yet (DTO mapping lands in PR-M2.3).
2. Build `TabRouter` (Domain store) + `NotificationStore` (Domain store).
3. Build `BottomTabBar` (organism) — pure UI; consumes `TabRouting` protocol via DI.
4. Build `AwardDetailPlaceholder` — consumes existing `ErrorStateView` from M1; primary button "Quay về SAA 2025" → `router.reset(to: .home)`.
5. Build `ComingSoonPlaceholder(variant: Variant)` — single view re-using `ErrorStateView` from M1; `Variant` enum = `.compose / .kudosFeed / .search / .profile`. Each variant maps to a localised title + back-CTA; loads zero data. Used by every M2-unimplemented destination so M3 / M4 / M5 can swap variants individually with no wider refactor.
6. Build `UnreadDotBadge` (atom) — receives `Bool` input; renders / hides accordingly. Pure-presentation.
7. Update `RootView` switch — exhaustive over `AppRoute`. Remove the M1 `default → LoginView` fall-through. Bind:
   - `.home` → temporary `HomePlaceholder` (kept only for this PR; replaced in PR-M2.2).
   - `.awardDetail(kind: _)` → `AwardDetailPlaceholder`.
   - `.writeKudo(_)` → `ComingSoonPlaceholder(variant: .compose)`.
   - `.sunKudos` and `.allKudos` → `ComingSoonPlaceholder(variant: .kudosFeed)`.
   - `.searchSunner` → `ComingSoonPlaceholder(variant: .search)`.
   - `.profileMe(_)` → `ComingSoonPlaceholder(variant: .profile)`.
   - `BottomTabBar` mounted as `safeAreaInset(.bottom)` of the tab content.
8. Wire DI in `Container`: register `TabRouter`, `NotificationStore`, factories for any placeholder VMs (none today — placeholders are stateless).

### Phase 2 — Core MVP: countdown + bell (PR-M2.2, US1 + US3)

1. RxTest scenarios for `HomeViewModel`:
   - `viewAppeared → countdown emits CountdownVM { days, hours, minutes }` (uses `TestScheduler` to advance time virtually).
   - `notificationStore.unreadCount = 0` → `hasUnreadNotifications == false`.
   - `notificationStore.unreadCount > 0` → `hasUnreadNotifications == true`.
   - `eventTargetDate ≤ now` → `countdown.hasEnded == true`, all of `days / hours / minutes` clamp to `0`, the `Driver<Bool>` driving the "Coming soon" label visibility flips to `false` (Q1 resolution).
2. Implement `EventSchedule` from `AppConfig`; build `CountdownVM` computation (pure function, easy to test).
3. Implement `CountdownTimerView` — consumes `CountdownVM`; respects Reduced Motion (no animation when enabled).
4. Implement `HomeHeader` — re-uses M1's `LanguageSwitcherChip` + `LanguagePickerDropdown`; new search icon button + bell button consume `UnreadDotBadge`.
5. Implement `NotificationRepositoryImpl` — start with the HEAD count and the Realtime subscription (writes can wait for PR-M2.5). Three failure modes to handle explicitly (per spec §Edge Cases):
   - **Realtime channel disconnects mid-session** → `PollingFallback` (30 s) takes over; both feed the same relay; last value wins.
   - **Realtime channel fails to subscribe at all** (WS blocked / handshake error) → start the 30 s polling relay immediately; never block the Home render or the initial badge state on the WS handshake.
   - **Realtime emits a row with `read_at != nil`** → defensive client-side filter drops it before it reaches `NotificationStore.unreadCount` (Supabase RLS shouldn't deliver these but the filter is cheap insurance).
6. Implement `ObserveUnreadNotificationsUseCase` — wraps `NotificationRepository.observeUnreadCount()`; on subscribe the use case feeds into `NotificationStore.unreadCount`. Bell-dot retention semantics (per spec US3 AS4 + Edge Cases):
   - **First fetch of a session fails** → `hasUnreadNotifications` stays `false` (suppress the dot to avoid a wrong badge); the use case retries on next `viewAppeared` / refresh.
   - **Mid-session fetch fails** *after* a successful previous fetch → keep the last known good value of `unreadCount` (do NOT flicker the dot off). Implemented via `materialize` + `scan` over the source: errors map to `.lastSuccess` instead of resetting the relay.
7. Build minimal `HomeView` (header + countdown + skeleton for awards + skeleton for kudos + FAB stub + tab bar) — NO awards / kudos data yet.
8. XCUITest: cold-launch shows live countdown text and bell-dot reflects a seeded `notifications` row.

### Phase 3 — Awards teaser + Home feed (PR-M2.3, US2)

1. RxTest: `awards.loaded([…3+ rows]) → AwardsTeaserState.loaded`, `error → AwardsTeaserState.error`, `empty → AwardsTeaserState.empty`.
2. Implement `AwardKind` (full enum with bilingual title/description accessors).
3. Implement `AwardRepositoryImpl` + `AwardDTO` — maps `awards` row → `AwardTeaser`. Asserts `kind` matches `AwardKind.allCases` (defensive).
4. Implement `FetchAwardsUseCase` (thin wrapper around `awardRepository.teaser()`).
5. Implement `FetchHomeFeedUseCase` — composes `Single.zip(fetchAwards, fetchKudosBanner, fetchInitialUnreadCount)` → `HomeFeed`.
6. Implement `AwardCardView` molecule — `Image("awards/<artwork_asset_key>")` (Q6 default = bundled). Description truncates with ellipsis at compile-time `.lineLimit(2)`.
7. Implement `AwardCardsRow` — horizontal `ScrollView` with lazy `LazyHStack`.
8. Wire empty / error states inline — error row tap → re-runs `FetchAwardsUseCase`.
9. Tap `Chi tiết` on a card → `router.reset(to: .awardDetail(kind: card.kind))` → `AwardDetailPlaceholder` (already in place from PR-M2.1).
10. Integration test against Supabase staging awards table.

### Phase 4 — Remaining sections + interactions (PR-M2.4, US4 / US5 / US6 / US7)

1. Implement `KudosBannerView` molecule — for M2 reads `KudosHighlightRepositoryImpl.current()` which returns the bundled-asset placeholder path. Q7 swap is M4's job.
2. Implement `WriteKudoFAB` — TWO tap zones (per spec Q3 default = match Figma):
   - Pen icon → `router.reset(to: .writeKudo(recipientId: nil))` → `ComingSoonPlaceholder(variant: .compose)` (already wired in PR-M2.1; M4 swaps to the real composer against the same case).
   - Sun\*Kudos `S` → `router.reset(to: .sunKudos)` → `ComingSoonPlaceholder(variant: .kudosFeed)` (M4 swaps to the real Kudos feed against the same case).
   - Per-zone debounce window of 300 ms + per-zone in-flight guard (US4 AS3). The in-flight guard is **cleared on Home's `onAppear`** (US4 AS5) so returning to Home re-arms both zones; implemented by binding `viewAppeared` → `inFlightSubject.onNext(.idle)` inside `HomeViewModel`.
3. Implement `ABOUT AWARD` / `ABOUT KUDOS` hero CTAs → emit `HomeAnchor.awards` / `.kudos` on `scrollTo: Signal<HomeAnchor>`; `HomeView` uses `ScrollViewReader` to scroll.
4. Implement search icon nav → `router.reset(to: .searchSunner)` → `ComingSoonPlaceholder(variant: .search)` (M5 swaps to the real search against the same case).
5. Implement language chip tap → reuses M1 `LanguagePickerDropdown` overlay pattern (already in `LoginView`).
6. Implement pull-to-refresh — `pullToRefresh.flatMapLatest { fetchHomeFeedUseCase.execute() }`; `isRefreshing` toggled by `do(onSubscribe:)` / `onDispose:`.
7. XCUITest: chip → dropdown → select EN → labels swap; pull-to-refresh resolves within `SC-HOME-4` budget; FAB tap zones reach the right placeholders.

### Phase 5 — Tab bar polish + observability (PR-M2.5, US8)

1. Wire `BottomTabBar.tabTapped` → `tabRouter.set(_)` → `RootView` switches.
2. Active-re-tap on SAA: `activeTabReTapped` → emits `HomeAnchor.top` → `ScrollViewReader` scrolls to top.
3. Implement `MarkNotificationReadUseCase` + `MarkAllNotificationsReadUseCase` (used by Notifications spec; defined here so the unread store updates correctly when the user marks-all-read in the inbox).
4. Wire all `analytics.track(.home_*)` calls — every event from spec §State Management § Analytics, no PII.
5. Performance pass:
   - Cold-launch (cached session) → first content < 800 ms (SC-HOME-1) — measure via `os_signpost`.
   - Awards fetch + render < 1.2 s (SC-HOME-2).
   - Pull-to-refresh < 1.5 s (SC-HOME-4).
   - Tab-switch latency < 100 ms (SC-HOME-6).
6. VoiceOver walk-through script — focus order verified per spec §Behavioral Requirements.
7. Final `xcodebuild` — zero warnings (Constitution §Workflow).

### Risk Assessment

| Risk | Probability | Impact | Mitigation |
|---|---|---|---|
| ~~Q1 copy not finalised~~ | — | — | **Resolved 2026-04-27**: clamp at zero + hide "Coming soon"; no extra copy needed. |
| Awards RLS policy not applied to staging before PR-M2.3 → fetches return 403 | Low | High | Q5 resolved 2026-04-27 (authenticated-only). Apply the migration on staging in PR-M2.3 prep; integration test asserts the policy is in place |
| Q7 bundled banner asset diverges from M4 dynamic source | Low | Low | `KudosHighlightRepository` protocol abstracts the source; M4 swap is one-impl change |
| Realtime channel disconnects in flaky network → unread badge stale | Med | Med | 30 s polling fallback (PR-M2.2); both share the same use-case output (last value wins) |
| `BottomTabBar` integration with `safeAreaInset` causes Dynamic Island overlap on iPhone 17 family | Low | Low | XCUITest harness covers iPhone 17 + iPad in landscape; M1 already exercised this safe-area pattern |
| Awards detail unavailable in M2 → user taps `Chi tiết` and lands on a placeholder | High (by design) | Low | Placeholder is the documented Q2 resolution; analytics distinguish "M2 placeholder tap" from real detail tap so PM can measure handoff readiness |
| `eventTargetDate` already passed (2026-04-27 > 2025-12-26) → countdown is permanently `0 / 0 / 0` | High (current reality) | Low | This is the documented zero-state per US1 AS4 + Q1 resolution: values clamped to zero, "Coming soon" label hidden, no extra copy. |

### Estimated Complexity

| Layer | Complexity |
|---|---|
| **Domain** | Medium — 7 new use cases, 2 new stores, 6 new entities |
| **Data** | Medium — Realtime subscription wrapper + polling fallback are new patterns |
| **Presentation** | Medium-High — first multi-component scrollable surface; first tab-bar shell |
| **Testing** | Medium — first Realtime + first composed `Single.zip` to test |

Total: ~7–10 working days for one engineer; can run two streams (Engineer-A on Phases 0–2, Engineer-B on Phase 3 + 4) once Phase 1 lands.

---

## Visual Parity Strategy

Process refinement for M2 (replaces the post-M1 "deferred visual fidelity" pattern that caused icons / images / gradients to silently miss merge on Login):

- **`design-style.md`** is a single document at `.momorph/specs/OuH1BUTYT0-home/design-style.md`, **incrementally authored** during M2.
- **Seeded by US1's parity task** (Phase 3) — adds the global tokens (color palette, typography ladder, spacing scale, screen-level vertical anchor map, header layout) sourced from the Figma frame `[iOS] Home` (`6885:8978`).
- **Appended by every subsequent US phase's parity task** — each phase adds the section for its own components (Awards section, Kudos section, FAB, BottomTabBar, etc.).
- **Source of truth** is always Figma queried live via `query_section` / `get_node_context` / `list_frame_styles` against the Node IDs in `spec.md` §Component Behavior. The `list_frame_styles` MCP output is a CSS approximation — when the Figma color picker disagrees, **trust the picker** (this lesson is from the M1 Login gradient deviation).
- **Figma drift freeze gate** — T103 (seed) records the root frame's `lastModified` timestamp (via `mcp__momorph__get_node` against `6885:8978`) into the `design-style.md` header as the **parity baseline**. Every subsequent parity task (T104–T110) MUST re-fetch the timestamp of every Figma node it touches and **STOP if any node's `lastModified` is newer than the baseline**. The implementer then escalates to Designer + PM: either (a) accept the new design and re-run T103 to bump the baseline (which forces a re-verify of every previously-shipped US phase against the new tokens), or (b) Designer reverts the change. No parity task may silently proceed against a drifted node — that is exactly how M1 Login ended up shipping a stale gradient. The baseline + every per-node timestamp lives in a `## Parity Baseline` table at the top of `design-style.md`.
- **Asset binaries** (artwork PNGs, banner image) are fetched via `mcp__momorph__get_media_files` against the relevant Node IDs and committed to `Assets.xcassets/` — listed as `[P]` tasks alongside the structural component tasks (T052, T053).
- **Known Deviations** section at the end of `design-style.md` captures every intentional substitution (e.g. Montserrat → SF Pro for M1; flag glyphs → emoji on iOS) with Designer sign-off date.
- **Merge gate**: a US phase is NOT complete until its visual-parity task is checked off. The PR description must include a side-by-side screenshot of the rendered View vs the Figma frame for every component the phase touches.

This mirrors the recovery strategy applied retroactively to Login (`8HGlvYGJWq`) on 2026-04-27, where `design-style.md` was authored after the fact to recover from the deferred-fidelity bug. M2 builds it the right way the first time.

---

## Integration Testing Strategy

### Test Scope

- **Component / Module interactions**: `HomeViewModel` ↔ `FetchHomeFeedUseCase`; `NotificationStore` ↔ `ObserveUnreadNotificationsUseCase` ↔ Realtime; `BottomTabBar` ↔ `TabRouter` ↔ `RootView`.
- **External dependencies**: `supabase-swift` (Postgres + Realtime); `ASWebAuthenticationSession` is NOT touched by Home.
- **Data layer**: real Supabase staging project for awards + notifications; per-test seeded fixtures.
- **User workflows**: cold-launch → countdown + bell; tap card → placeholder; pull-to-refresh → state machine.

### Test Categories

| Category | Applicable | Key scenarios |
|---|---|---|
| View ↔ ViewModel (Rx → SwiftUI) | Yes | Loading / error / success bindings on `HomeView` per section; bell-dot on / off |
| UseCase ↔ Repository | Yes | `FetchHomeFeed` composes 3 sources — test partial-failure semantics; `ObserveUnreadNotifications` switches sources on Realtime disconnect |
| Repository ↔ Supabase | Yes | `awards` SELECT + RLS-allowed / RLS-denied; `notifications` HEAD with `count: "exact"`; Realtime channel emits INSERT |
| Auth flow | No | Home assumes a valid session; M1 covers auth flow |
| RLS policy enforcement | Yes | Verify `notifications` SELECT only returns rows where `recipient_id = auth.uid()`; verify `awards` SELECT returns rows for authenticated requests AND returns 403 / empty for anon-key requests (Q5 = authenticated-only) |
| Accessibility | Yes | All P1 + P2 user stories at AX5; VoiceOver order asserted |

### Test Environment

- **Type**: iPhone 17 simulator (Xcode 17+); CI uses macOS-14 runner.
- **Test data**: seeded staging Supabase project: 6 `awards` rows + 3 `notifications` rows (1 unread, 2 read) for `qa-allowed@sun-asterisk.com`.
- **Isolation**: per-test reset of `notifications.read_at` via SQL fixture; awards table is read-only and seeded once.

### Mocking Strategy

| Dependency | Strategy | Rationale |
|---|---|---|
| `supabase-swift` Auth | Real (staging); mocked at `AuthRepository` for VM unit tests | Same as M1 |
| `supabase-swift` Postgres | Real (staging) for integration; mocked at repo protocol for VM tests | Determinism; staging integration runs in CI gate |
| `supabase-swift` Realtime | Mocked via `RealtimeUnreadChannel` test double emitting controlled events | Realtime is SDK-native and hard to drive deterministically; hide behind protocol |
| `AppConfig.eventTargetDate` | Injected via init parameter in tests | Lets `CountdownVMTests` test boundary cases (event-passed, exactly-now, days-mode, hours-mode) |
| Notification fixture | Real seeded staging row | Verifies Realtime path end-to-end |

### Test Scenarios Outline

1. **Happy path**
   - [ ] US1 cold-launch → countdown text matches `eventTargetDate − fixedNow`; event-info copy is localised.
   - [ ] US2 awards fetch returns 6 rows; AwardCardView renders all; tap card → placeholder pushed.
   - [ ] US3 seeded unread → bell dot ON; mark-all-read in Notifications → Realtime emits → dot OFF.
   - [ ] US6 pull-to-refresh re-fires all 3 queries; updated rows reflect.
2. **Error handling**
   - [ ] US2 awards 5xx → inline retry row; tapping retry re-fires.
   - [ ] US3 Realtime disconnect → polling kicks in within 30 s; no UI flicker.
   - [ ] US3 Realtime fails to subscribe at all (WS blocked) → polling starts immediately on first `viewAppeared`; Home render is not blocked on the WS handshake.
   - [ ] US3 first-load HEAD failure → dot suppressed (no false positive).
   - [ ] US3 mid-session HEAD failure (after a prior success in the same session) → dot retains last known good value (does NOT flicker off).
3. **Edge cases**
   - [ ] US1 AS4 event-passed → countdown clamps to `0 / 0 / 0`; "Coming soon" label hidden; no "Event Ended" copy rendered.
   - [ ] US4 AS3 double-tap FAB pen → only one placeholder push.
   - [ ] US4 AS5 navigate away from Home then return → FAB tap zones re-arm on `onAppear` (in-flight guard cleared per-zone).
   - [ ] US8 active-re-tap on SAA → ScrollView scrolls to `top` anchor.
   - [ ] Realtime emits a new notification with `read_at` already set → defensive client-side filter drops it; `unreadCount` does NOT increment.
   - [ ] Pull-to-refresh during initial load → `flatMapLatest` cancels initial.

### Tooling & Framework

- **Test framework**: XCTest (unit), RxTest / RxBlocking (Rx), XCUITest (UI).
- **CI integration**: existing `.github/workflows/ci.yml` runs all three jobs on every PR.
- **Coverage**: enforce no regression on Domain layer (`xccov` baseline check).

### Coverage Goals

| Area | Target | Priority |
|---|---|---|
| Domain use cases | 95%+ | High |
| ViewModels (Rx) | 90%+ | High |
| Data repositories | 80%+ | High |
| Shared SwiftUI components | 70%+ (snapshot or behavioural) | Medium |
| XCUITest critical paths | US1 happy path + US3 bell-dot + US8 tab-switch | High |

---

## Dependencies & Prerequisites

### Required before start

- [x] Constitution v1.1 reviewed (post-M1 amendments — `nonisolated` default, design-style.md mandatory).
- [x] M1 (Auth) merged — Home depends on `AuthStore`, `LocaleStore`, `LanguageSwitcherChip`, `LanguagePickerDropdown`, `ErrorStateView`, `AppRoute` (extended), `Container.bootstrap()` fresh-install gate.
- [x] Spec reviewed (round 2 — 2026-04-27, includes Q2 resolution).
- [x] Database migrations 0024 (notifications) + 0025 (awards) applied to staging.
- [x] **Q5 resolved 2026-04-27** — `public.awards` policy is `USING (auth.uid() IS NOT NULL)`. Migration applied to staging before PR-M2.3 review.
- [x] **Q1 resolved 2026-04-27** — countdown clamps to `0 / 0 / 0` and the "Coming soon" label is hidden when `eventTargetDate ≤ now`. No "Event Ended" copy; no `home.event.ended` localisation key.
- [ ] Awards rows seeded in staging `public.awards` (6 canonical kinds, bilingual). Owned by Tech lead + Content team; can land any time before PR-M2.3.
- [ ] Realtime RLS rules verified for `public.notifications` (replicates SELECT policy on the WS channel) — staging integration test in PR-M2.2.

### Open Questions (forwarded from spec.md)

- ~~**Q1**~~ — Resolved 2026-04-27 (clamp at zero + hide "Coming soon"; no extra copy).
- **Q3** (FAB simplification) — default = match Figma (2 tap zones). Approval to simplify lands as a 1-line VM change + analytics rewrite.
- **Q4** (Search scope) — owned by Kudos cluster; M2 just wires nav to placeholder.
- ~~**Q5**~~ — Resolved 2026-04-27 (authenticated-only RLS).
- **Q6** (Award artwork delivery) — default = bundled asset; Q6 swap to Storage is a future delta on `AwardCardView`'s image source.
- **Q7** (Kudos banner) — default = bundled asset; M4 swaps to dynamic.

### External dependencies

- Supabase staging project (existing).
- Award artwork bundle (6 PNGs / SVGs at `Assets.xcassets/awards/`) — Phase 0 deliverable, owned by Design.
- Kudos banner bundled asset (1 PNG) — Phase 0 deliverable.

---

## Definition of Done (M2)

Per Constitution §Workflow:

- [ ] All US1–US8 acceptance scenarios green on simulator.
- [ ] XCUITest cold-launch + countdown + tab-switch + bell-dot green in CI.
- [ ] VoiceOver pass at AX5 on Home + AwardDetailPlaceholder.
- [ ] No new SwiftLint warnings; no `TODO` without an issue link.
- [ ] No service-role key in bundle (CI secret-scan green).
- [ ] All 6 SC-HOME-* metrics within target on iPhone 12 + iPhone 17 baseline.
- [ ] PR descriptions include "Constitution check" + "Security review" lines.
- [ ] `Package.resolved` byte-identical with M1.
- [ ] M2 exit criteria from roadmap met: cold launch → Home shows countdown + bell. Composing a test kudo via SQL fixture → bell dot lights up + Notifications inbox prepends N1 in real time (Notifications spec covers the inbox half).

---

## Next Steps

1. Run `/momorph.tasks` to break this plan into discrete, ordered, parallelisable tasks.
2. Open the 6 PRs sequenced above (PR-M2.0 → PR-M2.5).
3. Track Q3 / Q6 / Q7 progress; none block ship.

---

## Notes

- **Visual tokens for Home are authored INLINE during M2** (process refinement — supersedes the earlier post-M1 amendment that deferred them to a separate `/momorph.implement-ui` invocation). Each US phase ends with a Visual-Parity task that queries Figma directly (`query_section` / `get_node_context` / `list_frame_styles` against the Node IDs in `spec.md` §Component Behavior) and appends a section to `design-style.md`. Reason for the change: M1 Login showed that a deferred visual-fidelity step gets dropped under shipping pressure — moving the gate inside each US phase makes it impossible to mark the phase complete without verifying the rendered View matches the Figma frame.
- **`BottomTabBar` ownership**: shared by every authenticated screen; Home introduces it but it lives in `Presentation/Shared/Navigation/`. M3 / M4 / M5 consume the same component.
- **Realtime fallback discipline**: the polling relay is not "instead of Realtime" — it is the **fallback** when the Realtime channel reports `disconnected`. Both feed the same `NotificationStore.unreadCount` `BehaviorRelay`; the use case picks whichever is newer. This avoids race conditions between WS reconnect and polling tick.
- **Testing harness for Realtime**: `RealtimeUnreadChannel` is a protocol behind which the staging test uses the real SDK and the unit test uses a `PublishSubject<Int>`. Integration tests validate the end-to-end path; VM tests stay deterministic.
- **`AwardDetailPlaceholder` is a real route**: not a "TODO comment screen". It re-uses `ErrorStateView`, has back navigation, has analytics, has accessibility. M4's job is purely to swap the binding under the same `AppRoute.awardDetail(kind:)` case — zero ripple.
- **iPhone 17 family**: M1 already shipped Dynamic-Island-aware safe-area handling in `RootView` + `LoginView`. Home reuses the same `.background(...) { ... .ignoresSafeArea() }` pattern documented in `LoginView`.
