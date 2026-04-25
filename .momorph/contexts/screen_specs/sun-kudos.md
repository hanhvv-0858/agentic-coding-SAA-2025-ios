# Screen: [iOS] Sun*Kudos

## Screen Info

| Property | Value |
|----------|-------|
| **Figma Frame ID** | `fO0Kt19sZZ` (node `6885:9059`) |
| **Figma Link** | https://momorph.ai/files/9ypp4enmFmdK3YAFJLIu6C/screens/fO0Kt19sZZ |
| **Screen Group** | Sun\*Kudos cluster |
| **Platform** | iOS (SwiftUI) |
| **Status** | discovered |
| **Discovered At** | 2026-04-24 |
| **Last Updated** | 2026-04-24 |

---

## Description

`[iOS] Sun*Kudos` is the **Kudos tab root** — the home of the Sun\*Kudos
social programme. It presents the feed in **4 major blocks** plus the
persistent compose CTA:

0. **Compose CTA** — "Hôm nay, bạn muốn gửi kudos đến ai?" pill,
   appearing twice (once above Highlight, once elsewhere) — a reminder
   to write a Kudos.
1. **HIGHLIGHT KUDOS** — a curated carousel of featured kudos with
   two filter dropdowns (hashtag + phòng ban). Paginated (2/5 shown).
2. **SPOTLIGHT BOARD** — an **interactive pan/zoom canvas** scattering
   all Sunner names with their Kudos counts (e.g. `388 KUDOS`),
   complete with a **live ticker** (`08:30PM Nguyễn Bá Chức đã nhận
   được một Kudos mới`) and an in-board **search Sunner** input.
3. **ALL KUDOS** — a bottom section containing:
   - **Stats dashboard** (kudos received / sent / hearts + secret
     boxes opened / unopened + a button — same organism as Profile
     bản thân's dashboard, likely reused).
   - **10 Sunner nhận quà** — top-10 winners list.
   - **Preview list** of 3 recent kudo cards.
   - **"View all Kudos"** button → pushes `[iOS] Sun*Kudos_All Kudos`.

It sits under the shared `HomeHeader` (branding + language + search +
bell) and above the shared `BottomTabBar`. Filter dropdowns open as
sub-sheets (fold-in).

---

## Navigation Analysis

### Incoming Navigations (From)

| Source | Trigger | Condition |
|--------|---------|-----------|
| `[iOS] Home` | Tap `Chi tiết` under the Kudos section, or Tab `Kudos` | Always |
| `[iOS] Home` | Tap Tab `Kudos` | Tab switch |
| `[iOS] Notifications` | Tap N1/N2 body | Actually → ViewKudo, not here — excluded |
| Deep link | `app://kudos` | Any time |

### Outgoing Navigations (To)

| Target | Trigger | Confidence | Notes |
|--------|---------|------------|-------|
| `[iOS] Sun*Kudos_Gửi lời chúc Kudos` (`PV7jBVZU1N`) | Tap compose CTA pill (either position) | High | No pre-fill |
| `[iOS] Sun*Kudos_View kudo` (`T0TR16k0vH`) | Tap any kudo card (Highlight or preview list) | High | Pass `kudoId` |
| **Sub-sheet**: HashtagFilterSheet | Tap left filter dropdown | High | Fold-in — covered below |
| **Sub-sheet**: DepartmentFilterSheet | Tap right filter dropdown | High | Fold-in — covered below |
| (Next page / Prev page of Highlight) | Tap left/right chevron | High | In-screen pagination, no navigation |
| `[iOS] Sun*Kudos_Search Sunner` (`3jgwke3E8O`) | Tap "Tìm kiếm" input inside Spotlight Board | High | Different from the global header search |
| `[iOS] Profile người khác` (`bEpdheM0yU`) | Tap any Sunner name/avatar on the Spotlight Board | High | Pass `userId` |
| `[iOS] Profile người khác` | Tap any of "10 Sunner nhận quà" | Medium | Confirm during `/momorph.specs` |
| `[iOS] Sun*Kudos_All Kudos` (`j_a2GQWKDJ`) | Tap "View all Kudos" button at bottom | High | Pushes a list-only screen |
| Shared header: language chip / 🔍 / 🔔 | Header icons | High | Shared destinations |
| Tab switches | Tab Bar | High | Shared |

### Navigation Rules

- **Auth required**: Yes.
- **Tab root**: no back button in the shared header; user switches tabs
  or pushes detail screens.
- **Deep link**: `app://kudos` (default) and
  `app://kudos?hashtag=<tag>&dept=<id>` for pre-filtered entry.

---

## Component Schema

### Layout Structure

```
┌─────────────────────────────────────┐
│ StatusBar                            │
├─────────────────────────────────────┤
│ [Logo] [🇻🇳 VN ▾] [🔍] [🔔•]         │ ← HomeHeader (shared)
├─────────────────────────────────────┤
│  Hệ thống ghi nhận và cảm ơn         │ ← KV Kudos banner (shared with Award)
│  [Kudo logo]                         │
├─────────────────────────────────────┤
│  ┌────────────────────────────────┐  │
│  │ ✎ Hôm nay, bạn muốn gửi kudos │  │ ← Compose CTA pill
│  │   đến ai?                      │  │
│  └────────────────────────────────┘  │
├─────────────────────────────────────┤
│  HIGHLIGHT KUDOS                     │ ← section header
│  [Hashtag ▾]     [Phòng ban ▾]       │ ← 2 filter dropdowns (fold-in triggers)
│  ← [ KudoCard  ][ KudoCard  ][…] →   │ ← carousel (3 visible)
│                2/5                   │ ← pagination
├─────────────────────────────────────┤
│  SPOTLIGHT BOARD                     │
│  ┌ Tìm kiếm sunner ──────┐           │ ← inline search → Search Sunner
│  └────────────────────────┘          │
│  388 KUDOS                           │ ← total
│  ┌─────────────── pan/zoom ────────┐ │
│  │  Đỗ hoàng Hiệp   Dương thúy An │ │
│  │   Mai phương Thúy …             │ │ ← many names (size ∝ kudos count)
│  │   08:30PM Nguyễn Bá Chức đã    │ │
│  │   nhận được một Kudos mới      │ │ ← live ticker lines
│  └──────────────────────────────────┘ │
├─────────────────────────────────────┤
│  ALL KUDOS                           │
│  ┌ Stats dashboard ──────────┐       │
│  │ [5] Kudos nhận [25] gửi   │       │ ← reused organism from Profile bản thân
│  │ [25] ❤   ───   [25] Đã mở │       │
│  │ [25] Chưa mở              │       │
│  │ [ Open / Go-to-… ]        │       │
│  └───────────────────────────┘       │
│  10 SUNNER NHẬN QUÀ                  │ ← top winners row
│  [👤][👤][👤][👤][👤]…               │
│  [ KudoCard ]                        │
│  [ KudoCard ]                        │ ← preview of 3
│  [ KudoCard ]                        │
│  [ View all Kudos ]                  │ → `[iOS] Sun*Kudos_All Kudos`
├─────────────────────────────────────┤
│ [SAA] [Awards] [Kudos] [Profile]    │ ← Tab Bar
└─────────────────────────────────────┘
```

### Component Hierarchy

```
SunKudosScreen (SwiftUI View — tab content)
├── HomeHeader (shared)                              # header
├── BackgroundImage (Atom)                           # mm_media_bg
├── KVKudosBanner (shared Organism)                  # mms_A_KV Kudos (reused from Award detail)
├── WriteKudoPill (Molecule)                         # mms_A.1_Button ghi nhận ×2
├── HighlightSection (Organism)                      # mms_B_Highlight
│   ├── SectionHeader "HIGHLIGHT KUDOS"
│   ├── FilterRow (Molecule)                         # 2 dropdowns
│   │   ├── HashtagFilterDropdown  → sub-sheet
│   │   └── DepartmentFilterDropdown → sub-sheet
│   ├── HighlightCarousel (Organism)
│   │   └── KudoCard ×N (shared)                     # mms_B.3_KUDO - Highlight
│   ├── PageChevrons (Atom ×2)                       # prev / next
│   └── PageIndicator (Atom)                         # "2/5"
├── SpotlightBoardSection (Organism)                 # B.6
│   ├── SectionHeader "SPOTLIGHT BOARD"
│   ├── InlineSunnerSearch (Molecule)                # taps → Search Sunner screen
│   ├── TotalKudosLabel (Atom)                       # "388 KUDOS"
│   └── SpotlightCanvas (Organism)                   # pan/zoom interactive
│       ├── SunnerChip ×N (Atom, name, size ∝ kudos)
│       ├── LiveTickerLine ×M (Atom)                 # "HH:MM Name nhận kudos"
│       └── PanZoomControls (Molecule)               # mms_B.7.2 pan zoom
├── AllKudosSection (Organism)                       # mms_C_All kudos
│   ├── SectionHeader "ALL KUDOS"
│   ├── StatsDashboard (shared Organism)             # same as Profile bản thân
│   ├── TopWinnersRow (Organism)                     # mms_D.3 "10 SUNNER nhận quà"
│   │   └── WinnerAvatarCell ×10
│   ├── KudosPreviewList (Organism)
│   │   └── KudoCard ×3
│   └── ViewAllKudosButton (Atom)                    # → [iOS] All Kudos
└── BottomTabBar (shared)                            # nav bar
```

### Main Components

| Component | Type | Description | Reusable |
|-----------|------|-------------|----------|
| `KVKudosBanner` | Organism | Reused from Award detail | ✅ |
| `WriteKudoPill` | Molecule | Persistent compose CTA | ✅ (pattern reused on Profile người khác's Send Kudo CTA and possibly View Kudo) |
| `HashtagFilterDropdown` / `DepartmentFilterDropdown` | Molecule | Dropdown chip triggers | ✅ |
| `HighlightCarousel` | Organism | Paged horizontal carousel of `KudoCard`s | ✅ (pattern) |
| `SpotlightCanvas` | Organism | **Novel** — pan/zoom interactive Sunner cloud with live ticker | No (unique to this screen) |
| `TopWinnersRow` | Organism | Horizontal 10-sunner strip | Yes (could reappear in leaderboard contexts) |
| `KudoCard` | Organism | Shared (introduced in profile-me.md) | ✅ |
| `StatsDashboard` | Organism | Same organism as Profile bản thân | ✅ |
| `BottomTabBar` | Organism | Shared | ✅ |

---

## Sub-sheets (fold-in)

Both sub-sheets are filter pickers rendered over the screen. Their
`get_overview` confirms they are **full-screen frames with the parent
Sun\*Kudos content behind + a dropdown overlay added**. On iOS they
should be implemented as `.sheet(isPresented:)` with
`.presentationDetents([.medium])` anchored under the triggering chip.

### HashtagFilterSheet — `[iOS] Sun*Kudos_dropdown hashtag` (V5GRjAdJyb)

**Type**: filter sub-sheet (fold-in).

- Contents: `mms_A_Dropdown-Hashtag` — a vertical list of hashtag
  options (`Tag1`, `Tag2`, `Tag3`, …). Multi-select or single-select
  TBC with design during `/momorph.specs`. Rendering pattern suggests
  single-select (one highlighted).
- Behaviour: selecting a tag updates the Highlight carousel filter
  (`selectedHashtag`). Sub-sheet dismisses on selection (or on "Xong"
  if multi-select).
- State: `selectedHashtag: BehaviorRelay<HashtagID?>` lives in
  `SunKudosViewModel`.
- Analytics: `sun_kudos.filter_hashtag_changed`.

### DepartmentFilterSheet — `[iOS] Sun*Kudos_dropdown phòng ban` (76k69LQPfj)

**Type**: filter sub-sheet (fold-in).

- Contents: `mms_A_Dropdown-CEV` — list of departments (`Phòng ban 1`,
  `Phòng ban 2`, `Phòng ban 3`, …). Single-select.
- Behaviour identical to HashtagFilterSheet but drives `selectedDepartment`.
- State: `selectedDepartment: BehaviorRelay<DepartmentID?>`.
- Analytics: `sun_kudos.filter_department_changed`.

Both sheets share a common `FilterListSheetView` component parameterised
by the options list + selection binding. Consider extracting it into
`Presentation/Shared/Components/`.

---

## Form Fields (If Applicable)

One input field on the Spotlight Board: the inline **Sunner search**.
Tapping opens `[iOS] Sun*Kudos_Search Sunner` rather than typing
inline (no keyboard appears here); treat it as a **navigation trigger**
rather than a form field.

---

## API Mapping

Backend: **Supabase**.

### On Screen Load / Resume

| Call | Method | Purpose | Response usage |
|------|--------|---------|----------------|
| `supabase.auth.getSession()` | SDK | Auth guard | Redirect to Login |
| `supabase.from("kudos").select(...).eq("is_highlight", true)` + filters | GET `/rest/v1/kudos` | HIGHLIGHT carousel | 5 pages × 3 kudos = 15 sample |
| `supabase.rpc("spotlight_board", { limit: 200 })` | POST | SPOTLIGHT canvas | Returns `[{ user_id, name, kudos_count, x, y }]` — or positions computed client-side; confirm w/ backend |
| Supabase Realtime on `kudos` (INSERT) | WebSocket | Live ticker | Prepend lines to `LiveTickerLine` stream |
| `supabase.rpc("profile_stats", { uid })` | POST | Stats dashboard (current user) | Same RPC used by Profile bản thân |
| `supabase.from("kudos_top_winners").select(...).limit(10)` | GET | "10 Sunner nhận quà" | Top-10 winners by metric (kudos received? hearts?) — confirm |
| `supabase.from("kudos").select(...).order("created_at", desc: true).limit(3)` | GET | Preview list | Recent 3 kudos |
| `supabase.from("kudos").select("sum(hearts)")` (or cached) | GET | "388 KUDOS" total | Might also come from `spotlight_board` response |

### On User Action

| Action | Call | Method | Request | Response |
|--------|------|--------|---------|----------|
| Tap compose CTA pill | — | navigation | — | Push Gửi lời chúc (no prefill) |
| Open hashtag sub-sheet | `supabase.from("hashtags").select(...).order(...)` | GET | — | Populate sheet (on first open; cached afterwards) |
| Select hashtag | Re-run Highlight query with filter | GET | — | Replace carousel |
| Open department sub-sheet | `supabase.from("departments").select(...)` | GET | — | Populate sheet |
| Select department | Re-run Highlight query with filter | GET | — | Replace carousel |
| Prev / next chevron | — | local | — | Change carousel page |
| Tap kudo card | — | navigation | — | Push View kudo |
| Tap Spotlight Sunner | — | navigation | — | Push Profile người khác |
| Tap inline search | — | navigation | — | Push Search Sunner |
| Tap "View all Kudos" | — | navigation | — | Push `[iOS] All Kudos` |
| Pull-to-refresh | Re-run all loads | — | — | Update all blocks |

### Error Handling

| Error | Source | UI action |
|-------|--------|-----------|
| Session expired | Guard | Redirect to Login |
| Highlight load failed | REST | Inline retry row inside the section |
| Spotlight load failed | REST | Section placeholder "Không tải được bảng Sunner" |
| Realtime disconnect | WS | Silent fallback to polling every 30 s |
| Stats load failed | REST | Show dashboard placeholders with retry |
| Preview list load failed | REST | Section placeholder with retry |
| Filter apply failed | REST | Revert to previous filter; toast |

---

## State Management

### Local State (ViewModel — Principle III)

```swift
protocol SunKudosViewModel {
    // Inputs
    var viewAppeared: PublishRelay<Void> { get }
    var pullToRefresh: PublishRelay<Void> { get }
    var composeTapped: PublishRelay<Void> { get }
    var hashtagFilterTapped: PublishRelay<Void> { get }
    var departmentFilterTapped: PublishRelay<Void> { get }
    var hashtagSelected: PublishRelay<HashtagID?> { get }
    var departmentSelected: PublishRelay<DepartmentID?> { get }
    var carouselPrevTapped: PublishRelay<Void> { get }
    var carouselNextTapped: PublishRelay<Void> { get }
    var kudoTapped: PublishRelay<KudoID> { get }
    var sunnerTapped: PublishRelay<UserID> { get }
    var searchTapped: PublishRelay<Void> { get }
    var viewAllKudosTapped: PublishRelay<Void> { get }

    // Outputs
    var highlightPages: Driver<[[KudoCardVM]]> { get }
    var highlightPageIndex: Driver<Int> { get }
    var totalHighlightPages: Driver<Int> { get }
    var spotlightSunners: Driver<[SpotlightSunnerVM]> { get }
    var spotlightTotalKudos: Driver<Int> { get }
    var liveTicker: Driver<[TickerLineVM]> { get }      // last N lines
    var stats: Driver<ProfileStatsVM?> { get }
    var topWinners: Driver<[WinnerVM]> { get }
    var previewKudos: Driver<[KudoCardVM]> { get }
    var selectedHashtag: Driver<HashtagID?> { get }
    var selectedDepartment: Driver<DepartmentID?> { get }
    var isLoading: Driver<Bool> { get }
    var presentSheet: Signal<FilterSheet> { get }       // .hashtag | .department
    var navigate: Signal<AppRoute> { get }
    var errorToast: Signal<String> { get }
}
```

### Global State

| State | Store | R/W | Purpose |
|-------|-------|-----|---------|
| `AuthState` | `AuthStore` | R | Guard |
| `CurrentUser` | `AuthStore` | R | For stats RPC |
| `UnreadNotificationCount` | `NotificationStore` | R | Bell dot |
| `AppTab` | `TabRouter` | W | Assert `.kudos` selected |

---

## UI States

### Loading State

- Each block loads independently — progressive rendering.
- Highlight: 3 skeleton cards.
- Spotlight: skeleton canvas + "Đang tải…" label.
- Stats: skeleton pills.
- Top 10: skeleton avatars.
- Preview list: 3 skeleton cards.

### Error State

- Per-block retry as described in Error Handling.

### Success State

- All blocks rendered; live ticker scrolling; filters reflect current
  selection; "View all Kudos" button enabled.

### Empty State

- No highlights for the current filter → section copy "Chưa có Kudos
  nào cho bộ lọc này. Thử chọn bộ lọc khác?"
- Zero Sunners in Spotlight (impossible in prod but defensive) → copy
  "Hệ thống đang cập nhật…"
- Stats all zeros → show the dashboard; empty state copy for
  "Chưa có hoạt động".
- No kudos → hide the preview list + hide "View all" button.

---

## Accessibility (Principle II)

| Requirement | Implementation |
|-------------|----------------|
| Screen context | Announce `"Sun*Kudos"` on tab appear |
| Compose pill | `.isButton`; hint `"Viết lời ghi nhận"` |
| Filter dropdowns | `.isButton`; announce current selection, e.g. `"Bộ lọc hashtag: \(currentTag)"` |
| Highlight card | Composite label (same as Profile's KudoCard) |
| Spotlight Board | **Non-trivial**. Provide an accessibility-friendly alternative: a `accessibilityRepresentation` with a **text list** of Sunners + kudos counts (`"Danh sách Sunner: 1. Nguyễn Bá Chức 388 kudos. 2. …"`). VoiceOver users can tap a list row instead of navigating the pan/zoom canvas. |
| Live ticker | Announce as a `accessibilityLiveRegion(.polite)` but **throttle** to one announcement per 10 s to avoid overwhelming VoiceOver users |
| Top winners row | Each cell is a separate element `"Vị trí \(n): \(name), \(count) kudos"` |
| View all Kudos | `.isButton`; hint `"Xem toàn bộ Kudos"` |
| Dynamic Type | Highlight section reflows to vertical at AX3+; Spotlight Board uses the text-list alternative at any AX; preview list reflows naturally |
| Touch targets | Filter chips ≥ 44 pt; carousel chevrons ≥ 44 pt; Spotlight chips ≥ 44×44 |

---

## Responsive Behavior

| Device class | Layout |
|--------------|--------|
| iPhone portrait | As designed |
| iPhone landscape | Highlight carousel shows 2 cards; Spotlight Board fills width |
| iPad | Max width 720 pt centered; carousel shows 3 cards simultaneously |
| AX3+ | Spotlight Board switches to the text-list alternative |

---

## Analytics Events (Optional)

| Event | Trigger | Properties |
|-------|---------|------------|
| `sun_kudos.viewed` | On appear | `{ source }` |
| `sun_kudos.compose_tap` | CTA | — |
| `sun_kudos.filter_hashtag_changed` | Hashtag selection | `{ from, to }` |
| `sun_kudos.filter_department_changed` | Department selection | `{ from, to }` |
| `sun_kudos.highlight_carousel_page` | Prev/Next | `{ page }` |
| `sun_kudos.kudo_tap` | Kudo card | `{ source: .highlight / .preview }` |
| `sun_kudos.spotlight_sunner_tap` | Spotlight chip | — |
| `sun_kudos.spotlight_search_tap` | Inline search | — |
| `sun_kudos.view_all_tap` | Bottom CTA | — |

Principle V: no names, no user_ids in analytics.

---

## Design Tokens

| Token | Usage |
|-------|-------|
| `Color("BrandPrimary")` | Compose CTA, section headers |
| `Color("StatHighlight")` | Stats numbers |
| `Color("SpotlightChipBG")` | Sunner chip backgrounds |
| `Color("TickerText")` | Live ticker |
| Font: `.title2` → section titles; `.body` → ticker + chips; `.largeTitle` → "388 KUDOS" and stats digits; `.headline` → buttons |
| Asset: `Image("spotlight_board_bg")` — `Root further mo rong 1` backdrop |

---

## Implementation Notes

### Clean Architecture touch-points (Principle I)

- **Presentation**:
  `Presentation/SunKudos/Views/SunKudosView.swift`,
  `Presentation/SunKudos/ViewModels/SunKudosViewModel.swift`,
  `Presentation/SunKudos/ViewModels/SunKudosStateAdapter.swift`,
  `Presentation/SunKudos/Components/HighlightCarouselView.swift`,
  `Presentation/SunKudos/Components/SpotlightBoardView.swift`,
  `Presentation/SunKudos/Components/LiveTickerView.swift`,
  `Presentation/SunKudos/Components/TopWinnersRowView.swift`,
  `Presentation/SunKudos/Components/FilterListSheetView.swift` (shared by 2 sub-sheets),
  `Presentation/Shared/Components/KudoCardView.swift` (reused),
  `Presentation/Shared/Components/StatsDashboardView.swift` (extract from profile-me.md at implementation time),
  `Presentation/Shared/Components/WriteKudoPillView.swift`.
- **Domain**:
  `Domain/UseCases/FetchHighlightKudosUseCase.swift` (with `HashtagID?` +
  `DepartmentID?` + keyset `page` params),
  `Domain/UseCases/FetchSpotlightBoardUseCase.swift`,
  `Domain/UseCases/ObserveKudosTickerUseCase.swift` (Realtime),
  `Domain/UseCases/FetchTopWinnersUseCase.swift`,
  `Domain/Entities/SpotlightSunner.swift`, `TickerLine.swift`, `Hashtag.swift`,
  `Department.swift`.
- **Data**:
  `Data/Repositories/KudoRepositoryImpl.swift` — extend for highlight + top winners,
  `Data/Repositories/HashtagRepositoryImpl.swift`,
  `Data/Repositories/DepartmentRepositoryImpl.swift`,
  `Data/Remote/Spotlight/SpotlightRemoteDataSource.swift`.

### Reactive model (Principle III)

- **Filters**: combined signal
  ```swift
  Observable.combineLatest(selectedHashtag, selectedDepartment)
      .flatMapLatest { hashtag, dept in
          useCase.fetchHighlight(hashtag: hashtag, department: dept).asObservable()
      }
      .bind(to: highlightPagesRelay)
  ```
- **Live ticker**: Realtime subscription emits `Observable<TickerLine>`;
  `scan` into a bounded FIFO of last 10 lines.
- **Spotlight canvas**: loaded once per screen appearance; use a
  `LocalCache` to avoid refetch on tab re-focus within 60 s.
- **Search tap**: `Signal<AppRoute.searchSunner>`.

### Security (Principle V)

- RLS required on `kudos` (`status = 'active'` filter for non-authors).
- `spotlight_board` RPC should aggregate public counts only — it must
  NOT expose email or department-free PII.
- Realtime `kudos` channel must respect the same policy; live ticker
  messages must come pre-sanitised from the server (name + timestamp
  only — never body text).

### Edge cases

- Both filters cleared → default highlight query with no `eq` clauses.
- Pagination mid-filter change → cancel in-flight via `flatMapLatest`.
- Tab switched away while Spotlight is loading → cancel; reload on
  re-appear.
- Spotlight chip overlap on small screens → cap rendered chips to ~50;
  rely on the inline search for the full list.

---

## Analysis Metadata

| Property | Value |
|----------|-------|
| Analyzed By | `/momorph.screenflow` |
| Analysis Date | 2026-04-24 |
| Source | `get_overview` on `fO0Kt19sZZ` (depth 5) + 2 fold-in overviews + 1 verify overview |
| Verify result (`j_a2GQWKDJ`) | **Rejected fold-in — layout < 80% similar**. `All Kudos` uses `TopNavigation` + pure list (no KV banner, no Highlight, no Spotlight, no stats). Keeping it as **standalone** (row #20 in SCREENFLOW.md Screens table). |
| Needs Deep Analysis | Medium — Spotlight Board interaction + pagination semantics should be validated during `/momorph.specs` |
| Confidence Score | High for structure; Medium for exact Highlight filtering semantics (single-select vs multi-select on hashtags) and Spotlight positioning (client-random vs server-provided) |

### Next Steps

- [ ] Confirm filter selection semantics (single vs. multi).
- [ ] Confirm Spotlight Board positioning (client random vs server
      `x/y` vs metric-based layout like a word cloud).
- [ ] Confirm top-10 winners metric (kudos received? hearts? some combo).
- [ ] Extract `StatsDashboardView` as a shared component during
      implementation (Sun*Kudos + Profile bản thân both consume it).
- [ ] Introduce `SpotlightBoardView` accessibility alternative
      (text-list) as a hard requirement — not optional.
- [ ] Run `/momorph.specs 9ypp4enmFmdK3YAFJLIu6C fO0Kt19sZZ` before
      implementation.
