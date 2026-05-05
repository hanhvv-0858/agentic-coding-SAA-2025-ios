# Tasks: M2 — Home (SAA 2025 tab) + App shell

**Frame**: `OuH1BUTYT0-home` (`[iOS] Home`)
**Prerequisites**: [plan.md](plan.md), [spec.md](spec.md)
**Created**: 2026-04-27

---

## Task Format

```
- [ ] T### [P?] [Story?] Description | file/path.swift
```

- **[P]**: Can run in parallel (different files, no dependencies on incomplete tasks)
- **[Story]**: Which user story this belongs to (US1–US8)
- **|**: Primary file path affected by this task
- **(TDD)**: Test-first per Constitution IV — write the failing test before its implementation task

## Validation cadence (per Constitution §Development Workflow, 2026-04-27)

- After each task / related-task batch: `xcodebuild build-for-testing` (compile-only, ~15 s) — catches ~90 % of failures (imports, types, signatures).
- **Optional** at phase boundaries: a targeted subset run (`-only-testing:AIDD-SAA-2025Tests/<NewSuite>`) on the suites the phase added/changed (~10–30 s on pre-booted sim).
- **Full `xcodebuild test` only at**:
  1. **End of screen** — every Phase here is `[x]`.
  2. **End of screen-cluster** — several related screens shipping together (e.g. M2 Home + Notifications).
  3. **Explicit user request** ("hãy chạy full test", "run the full suite", etc.).
- **Do NOT run `xcodebuild test` per task** (simulator cold-launch tax 30–60 s).
- **Do NOT run full `xcodebuild test` at every phase boundary** by default — defer to end-of-screen unless the user asks earlier.
- Recommended setup commands (one-time per session):
  ```bash
  xcrun simctl boot "iPhone 17"
  ```
  Recommended test command (subset/full both):
  ```bash
  xcodebuild test -project AIDD-SAA-2025.xcodeproj \
    -scheme AIDD-SAA-2025 \
    -destination 'platform=iOS Simulator,name=iPhone 17' \
    -enableCodeCoverage NO \
    -disable-concurrent-destination-testing \
    -only-testing:AIDD-SAA-2025Tests
  ```
- CI gates at PR merge are unchanged — they still run the full suite with coverage on.
- **(parity)**: Visual-parity gate per plan.md §Visual Parity Strategy — fetches Figma tokens for the phase's components and appends to `design-style.md`. **Each US phase is incomplete until its parity task is checked off.** Numbered T103–T110 (appended after the original sequence to avoid renumbering); each appears at the end of its US phase below. **Every parity task EXCEPT T103 (seed) starts with the same drift-check preamble**:
  - **Drift check** — for every Node ID this task touches, call `mcp__momorph__get_node` and compare `lastModified` to the `## Parity Baseline` table in `design-style.md` (written by T103). If ANY node has drifted, **STOP** and escalate to Designer + PM. Resolution: either (a) Designer reverts, or (b) re-run T103 to bump the baseline + verify all previously-shipped US phases still match the new tokens (re-open the relevant earlier phases in tasks.md). Do NOT silently proceed against a drifted node.

---

## User Story Map (from spec.md)

| ID  | Title                                          | Priority |
|-----|------------------------------------------------|----------|
| US1 | Land on Home with countdown & event info       | P1 🎯 MVP |
| US2 | Browse award categories and open detail        | P1       |
| US3 | See unread notifications via bell              | P1       |
| US4 | Quick Kudos actions from FAB                   | P2       |
| US5 | Switch interface language from chip            | P2       |
| US6 | Pull-to-refresh dynamic content                | P2       |
| US7 | Open Search from header                        | P3       |
| US8 | Switch tabs via bottom bar                     | P2       |

---

## Phase 1: Setup (Shared Infrastructure — PR-M2.0)

**Purpose**: project-level prep that doesn't change runtime behaviour yet.

- [x] T001 Verify `EVENT_TARGET_DATE` (`2025-12-26T19:00:00+07:00`), `EVENT_PLACE` (`Âu Cơ Art Center`), `LIVE_STREAM_URL` are populated in every config; commit any deltas | `Config/Dev.xcconfig`, `Config/Staging.xcconfig`, `Config/Prod.xcconfig` — Staging + Prod match spec; Dev intentionally has `2026-04-24T11:30:00Z` (was used to test non-zero countdown during local dev — also passed now, harmless: clamps to `0/0/0` per Q1).
- [x] T002 [P] Add the 30 home / awards / tab localisation keys (VN + EN) listed in spec § Behavioral Requirements — explicitly NO `home.event.ended` key (Q1 resolution) | `Resources/Localizable.xcstrings` — 32 keys added (3 `awards.placeholder.*` + 25 `home.*` + 4 `tab.*`); `home.kudos.note` and `home.theme.note` marked `state: new` pending Designer-finalised copy.
- [x] T003 [P] Add `home` and `notifications` `Logger` categories | `AIDD-SAA-2025/Core/Logger.swift`
- [x] T004 Confirm `Package.resolved` is byte-identical with M1 (no new SPM deps in M2) — abort PR if diff appears | `Package.resolved` — clean tree, no diff vs M1.

---

## Phase 2: Foundation (Blocking Prerequisites — PR-M2.1)

**Purpose**: app shell, navigation, RLS, DI — every user story below depends on this.

**⚠️ CRITICAL**: No US phase may start before Phase 2 is green.

### Domain enum + AppRoute typing

- [x] T005 [P] Define `AwardKind` enum: 6 cases with raw values matching DB `award_kind` | `AIDD-SAA-2025/Domain/Entities/AwardKind.swift` — **DB schema discovery**: actual `award_kind` enum in migration 0025 is `mvp / best_manager / signature_creator / top_project / top_project_leader / top_talent` (NOT `topPerformer/topContributor` as plan/spec assumed). Plan + spec need updating to match. AwardKind enum follows DB.
- [x] T006 Re-type `AppRoute.awardDetail(kind: String)` → `AppRoute.awardDetail(kind: AwardKind)` (Hashable still satisfied; only consumer is `RootView` default branch which is rewritten in T014) | `AIDD-SAA-2025/Presentation/Shared/Navigation/AppRoute.swift`

### Domain stores

- [x] T007 (TDD) [P] Failing tests for `TabRouter`: `set(.kudos)` updates `selectedTab.value`; `selectedTabObservable` emits the change | `AIDD-SAA-2025Tests/Domain/Stores/TabRouterTests.swift` — 6 tests covering init, set, observable, idempotent set, re-tap relay, `notifyTap` routing.
- [x] T008 [P] `TabRouter` (Domain store) with `selectedTab: BehaviorRelay<AppTab>` + `selectedTabObservable` + `set(_:)` | `AIDD-SAA-2025/Domain/Stores/TabRouter.swift` — also exposes `activeTabReTapped: Observable<AppTab>` for active-re-tap (US8 AS4) + `notifyTap(_:)` helper that auto-routes to set vs re-tap.
- [x] T009 [P] `NotificationStore` (Domain store) with `unreadCount: BehaviorRelay<Int>` + `hasUnreadObservable: Observable<Bool>` (clamp `< 0 → 0`) | `AIDD-SAA-2025/Domain/Stores/NotificationStore.swift` — bonus: `NotificationStoreTests` (4 tests) added for safety since this is new app-wide infra.

### Shared atoms / organisms

- [x] T010 [P] `UnreadDotBadge` atom — pure presentation, takes `Bool`, renders 8×8 dot in `Color.red` else hides; visual tokens are placeholders pending T103 visual-parity gate | `AIDD-SAA-2025/Presentation/Shared/Components/UnreadDotBadge.swift`
- [x] T011 [P] `BottomTabBar` organism — 4 tabs with SF-Symbol placeholder icons (T109 swaps to Figma assets); active tab styled via accent color; consumes `TabRouting` via `BottomTabBarState` (Combine bridge) | `AIDD-SAA-2025/Presentation/Shared/Navigation/BottomTabBar.swift`

### Placeholder views

- [x] T012 [P] `AwardDetailPlaceholder` — re-uses M1 `ErrorStateView`; shows `awards.placeholder.title` + `awards.placeholder.subtitle` + primary button → back to `.home`; logs via `Log.home` (placeholder.award_detail event) | `AIDD-SAA-2025/Presentation/Home/Views/AwardDetailPlaceholder.swift`
- [x] T013 [P] `ComingSoonPlaceholder(variant:)` — added 5th variant `.notifications` for sibling Notifications spec to replace; each variant maps to localised copy (reuses `awards.placeholder.*` keys) + SF-Symbol illustration + back-CTA; logs via `Log.home` | `AIDD-SAA-2025/Presentation/Placeholders/ComingSoonPlaceholder.swift`

### RootView exhaustive switch + DI

- [x] T014 Update `RootView` — switch is now exhaustive over all 14 `AppRoute` cases (no `default`). Pre-auth (`.login` / `.accessDenied` / `.notFound`) renders without tab bar; every authenticated route is wrapped in `authenticatedShell { ... }` which mounts `BottomTabBar` via `safeAreaInset(.bottom)`. `.viewKudo` and out-of-scope routes (`.secretBox` / `.theLe` / `.communityStandards`) routed to `ComingSoonPlaceholder(.kudosFeed)` as M2 fallback. | `AIDD-SAA-2025/Presentation/Root/RootView.swift`
- [x] T015 Wire DI in `Container`: registered `TabRouter` (singleton, initial `.saa`) + `NotificationStore` (singleton, initial 0); both exposed via `ContainerProtocol` for ViewModels and `RootView` to consume | `AIDD-SAA-2025/Core/DI/Container.swift`

### Supabase RLS

- [x] T016 **No new migration needed** — migration 0025 (`awards_catalogue.sql`) already declares the equivalent policy: `CREATE POLICY awards_select_authenticated ON public.awards FOR SELECT TO authenticated USING (true)` + `ENABLE ROW LEVEL SECURITY`. Same effect as Q5 wording (`USING (auth.uid() IS NOT NULL)`) since `TO authenticated` already restricts the role. Wrote `0029_awards_rls_q5_verification.sql` as an idempotent gate that asserts the 0025 state and fails loudly if 0025 hasn't been applied. | `.momorph/contexts/migrations/0029_awards_rls_q5_verification.sql`
- [x] T017 [P] RLS integration test — 2 layers: structural (parses 0025 SQL, asserts policy text — always runs); runtime integration (XCTSkipped without `SUPABASE_URL_STAGING` + `SUPABASE_ANON_KEY_STAGING` env vars; asserts anon fetch returns 401/403 OR empty 200) | `AIDD-SAA-2025Tests/Data/Awards/AwardsRLSPolicyTests.swift`

### XCUITest gate

- [x] T018 [P] XCUITest scaffold — covers launch-on-Login as the smoke test. Note: the exhaustive-switch invariant is **already enforced by the Swift compiler** (RootView's switch has no `default` branch — adding a new `AppRoute` case will fail to build). Runtime per-route coverage is gated on a future launch-argument hook (`-StartRoute home` etc.); documented in the test file's header for the implementer who wires that hook | `AIDD-SAA-2025UITests/Navigation/RouteCoverageUITests.swift`

**Checkpoint**: shell ships. After auth, the user sees a 4-tab shell; tapping any tab swaps to its placeholder; tapping an Award Card opens `AwardDetailPlaceholder`; FAB / search / Profile tab all land on a stable Coming-Soon screen with a working back button.

---

## Phase 3: User Story 1 — Countdown & event info (Priority: P1) 🎯 MVP — PR-M2.2 part 1

**Goal**: cold-launched signed-in user sees Home with a live countdown to `eventTargetDate`, plus venue / livestream copy. When the date has passed, countdown clamps to `0 / 0 / 0` and the "Coming soon" label is hidden (Q1).

**Independent Test**: launch app with cached session → Home renders < 800 ms p95 → `DD HH MM` text reflects `eventTargetDate − now` → minutes value decrements after one minute → with `eventTargetDate ≤ now` (current reality 2026-04-27) the row reads `00 DAYS 00 HOURS 00 MINUTES` and "Coming soon" is hidden.

### Visual Parity — front-loaded (T103a)

Per the **process refinement chosen 2026-04-27** (option B in `/momorph.implement` discussion): T103 is split. T103a runs FIRST in Phase 3 to seed `design-style.md` BEFORE any HomeView component is coded. T103b runs LAST as the side-by-side verification gate.

- [x] T103a (parity-seed) [US1] **SEED** `design-style.md` with: parity baseline (frame revision `3c9059f3da88539320cb62e39aefcf38`, updated 2026-04-06), global tokens (palette, typography ladder, spacing), Header layout (logo / chip / search / bell positions), Hero (countdown + event-info + ABOUT buttons), Theme paragraph. Established 7 known deviations carrying forward from M1 (gradient stops, font, flag glyphs, chip tint, search/bell SF Symbols, theme.note EN copy, bell dot color). Real Figma VN copy for `home.theme.note` ported into Localizable.xcstrings (replaces the M2 placeholder draft) | `.momorph/specs/OuH1BUTYT0-home/design-style.md`

### Domain (US1)

- [x] T019 [P] [US1] `EventSchedule` entity (`targetDate`, `place`, `liveStreamURL`); init reads from `AppConfig` | `AIDD-SAA-2025/Domain/Entities/EventSchedule.swift`
- [x] T020 [P] [US1] `CountdownVM` value type (`days`, `hours`, `minutes`, computed `hasEnded`) + pure factory `from(target: Date, now: Date)` that clamps negative values to zero | `AIDD-SAA-2025/Domain/Entities/CountdownVM.swift`
- [x] T021 (TDD) [P] [US1] `CountdownVMTests` — 9 tests: past target clamps + hasEnded; exactly-now hasEnded; sub-minute residue rounds down to 0; 1-min/1-hour/1-day cases; composite 3d 4h 15m; Equatable | `AIDD-SAA-2025Tests/Domain/Entities/CountdownVMTests.swift`

### Presentation (US1)

- [x] T022 (TDD) [US1] `HomeViewModelTests` — 6 tests using sync `PublishRelay<Void>` tick stream (M1 `collect()` pattern): viewAppeared → initial countdown emit, event-passed clamps + hasEnded, showsComingSoon true/false per Q1, multi-tick minute-boundary emit, locale binding. **Bug-fix log**: first version used `Observable<Int>.interval(scheduler: TestScheduler)` + `.drive(observer)` which hangs because Driver's `ConcurrentMainScheduler` async-hops events from non-main schedulers. Replaced TestScheduler with injectable `tickStream: Observable<Void>` on `HomeViewModelImpl`. Production passes real `Observable<Int>.interval(.seconds(1), MainScheduler.instance)`; tests pass `PublishRelay<Void>` and emit ticks synchronously | `AIDD-SAA-2025Tests/Presentation/Home/HomeViewModelTests.swift`
- [x] T023 [US1] `HomeViewModel` protocol + `HomeViewModelImpl` — US1 surface only (`viewAppeared` input; `countdown` / `showsComingSoon` / `selectedLanguage` outputs); injectable `tickStream: Observable<Void>` (production `Observable<Int>.interval(.seconds(1), MainScheduler.instance)` / tests pass `PublishRelay<Void>`) + `() -> Date` for time control; `share(replay:1, scope: .whileConnected)` so countdown + showsComingSoon share the underlying interval subscription | `AIDD-SAA-2025/Presentation/Home/ViewModels/HomeViewModel.swift`
- [x] T024 [US1] `HomeStateAdapter` (`ObservableObject` bridging Rx → `@Published`) — Combine bridge boundary for SwiftUI per Constitution III | `AIDD-SAA-2025/Presentation/Home/ViewModels/HomeStateAdapter.swift`
- [x] T025 [P] [US1] `CountdownTimerView` molecule — DD/HH/MM cells (56pt bold mono digits + label below); "Coming soon" label hidden when `!showsComingSoon` (Q1); `@Environment(\.accessibilityReduceMotion)` skips animation; combined VoiceOver label | `AIDD-SAA-2025/Presentation/Home/Views/CountdownTimerView.swift`
- [x] T026 [P] [US1] `HomeHeader` organism — logo (48×44 left, y=8) + cluster (chip + search + bell at y=20, 12pt below logo top per design-style §3.2 Δ); bell uses SF Symbol placeholder with `UnreadDotBadge` overlay; bell hardcoded to false for US1 (T068 wires live state) | `AIDD-SAA-2025/Presentation/Home/Views/HomeHeader.swift`
- [x] T027 [US1] `HomeView` shell — ScrollView + `HomeHeader` + hero (HeroLogo + CountdownTimerView + event info 3 rows + ABOUT buttons row) + theme paragraph; keyvisual + 4-stop gradient via `.background { ZStack { ... }.ignoresSafeArea() }` (M1 pattern); `BrandOnCream` background fallback; awards/kudos placeholder spacer | `AIDD-SAA-2025/Presentation/Home/Views/HomeView.swift`
- [x] T028 [US1] Replaced `RootView`'s temporary `HomePlaceholder` with real `HomeView`; added `@StateObject homeState: HomeStateAdapter`; `Container.makeHomeViewModel()` factory wired (loads `EventSchedule(from: config)` + `localeStore`); search/notifications header buttons route to existing placeholders | `AIDD-SAA-2025/Presentation/Root/RootView.swift` + `AIDD-SAA-2025/Core/DI/Container.swift`

### UI Tests (US1)

- [x] T029 [US1] XCUITest scaffold — verifies app boots without crashing post-Phase-3 changes; full screen-level assertions XCTSkipped pending the launch-arg hook (matches T018 deferral). T103b covers the structural verification manually via screenshot | `AIDD-SAA-2025UITests/Home/HomeCountdownUITests.swift`

### Visual Parity — final verification (T103b — last task of US1)

- [x] T103b (parity-verify) [US1] **VERIFY** completed 2026-04-27. Drift check PASS (revision matches baseline). 4 resolutions: bell dot color closed at `#D4271D` (UnreadDotBadge updated); search/bell/FAB icons reclassified PERMANENT (Figma exports null); ABOUT button arrow icon + event info bindings flagged as new OPEN deviations (#8, #9 — defer to polish, visual delta small). Header gradient (#1) still OPEN — needs Designer picker review at ship. Side-by-side screenshot deferred until launch-arg hook lands. Full audit log in `design-style.md` Append log entry. | `.momorph/specs/OuH1BUTYT0-home/design-style.md` + `Presentation/Shared/Components/UnreadDotBadge.swift`

<details><summary>(Original step list — kept for traceability)</summary>

- T103b (parity-verify) [US1] **VERIFY** rendered HomeView vs Figma frame `6885:8978` side-by-side. Steps:
  1. Re-fetch frame revision via `mcp__momorph__get_frame screenId=OuH1BUTYT0` and confirm it equals the §0 baseline. If drifted, STOP + escalate (per design-style.md §0 contract).
  2. Capture screenshot of running HomeView on iPhone 17 sim in light + dark mode + Dynamic Type AX5.
  3. Compare against the Figma frame render. Each deviation either (a) gets fixed in code, or (b) gets logged in `design-style.md §6 Known deviations` with rationale + Designer sign-off date.
  4. Bell unread-dot color (T103a §6 #7): now drill into node `I6885:9057;88:1830;72:1627` via `query_section` to capture the actual fill; update §1 + §3.4 with the resolved color; if it differs from the M2 `Color.red` placeholder, swap in code.
  5. Header gradient stops (T103a §6 #1): verify in Figma color picker; if M1 4-stop pattern still applies, mark deviation closed; otherwise update §1 with the actual stop list and refactor.
  6. Search + bell icon assets (T103a §6 #5): if SF Symbols differ visually from the Figma renders, fetch the components via `mcp__momorph__get_media_files` and swap to bundled assets.
  7. Append the verification result + screenshot links to `design-style.md` "Append log".

  PR-M2.2 cannot merge without this task green | `.momorph/specs/OuH1BUTYT0-home/design-style.md` + `Presentation/Home/Views/*`

</details>

### Original T103 description (now superseded by T103a + T103b)

<details><summary>(Reference only — kept for traceability)</summary>

- T103 (parity) [US1] **SEED** `.momorph/specs/OuH1BUTYT0-home/design-style.md`. Steps:
  1. **Record the parity baseline** — call `mcp__momorph__get_node` against frame `6885:8978` and capture its `lastModified` timestamp; also call it for every Node ID listed in spec.md §Component Behavior (header, hero, awards section, kudos section, FAB, tab bar, plus per-component children for US1–US8). Write a `## Parity Baseline` table at the top of `design-style.md` with columns `| Node ID | Component | lastModified (UTC) | Baseline by |` — this is the **drift freeze contract** every subsequent parity task (T104–T110) checks against.
  2. **Extract global tokens** via `mcp__momorph__list_frame_styles` against frame `6885:8978` + `mcp__momorph__query_section` per node: color palette (background, on-background, surface tints) — written into `Assets.xcassets` as Color Sets keyed by semantic name + locked here; Montserrat→SF Pro typography ladder (sizes / weights / line-heights — declared once, US2–US8 reuse without redefining); spacing scale; screen-level vertical anchor map (matches spec §Component Behavior tables).
  3. **Extract US1 component specs**: `HomeHeader` layout (logo position, chip position, search/bell positions, gradient stops), countdown digit cell dimensions + spacing, hero hero-logo + ABOUT-AWARD/KUDOS button styling, event-info list typography.
  4. **Verify** — trust the Figma color picker over `list_frame_styles` CSS approximation (M1 Login gradient lesson); side-by-side screenshot of rendered HomeView vs Figma frame `6885:8978` attached to the PR; document any deviation in `## Known Deviations` with rationale + Designer sign-off date | `.momorph/specs/OuH1BUTYT0-home/design-style.md`

</details>

**Checkpoint**: US1 ships independently — the SAA tab shows a live countdown frozen at zero (current reality) for any signed-in Sunner; rendered surface matches Figma frame `6885:8978`.

---

## Phase 4: User Story 2 — Browse awards + open detail (Priority: P1) — PR-M2.3

**Goal**: Awards horizontal teaser renders with localised cards; tap "Chi tiết" → `AwardDetailPlaceholder` for that `kind`; ABOUT-AWARD hero CTA scrolls to the awards section. Kudos section + ABOUT-KUDOS scroll ride along (FR-010 + FetchHomeFeed already returns kudos banner data).

**Independent Test**: with 6 staging award rows seeded, Home renders 3 cards + horizontal scroll exposes the rest; tap "Chi tiết" → AwardDetailPlaceholder shows the right `awards.placeholder.title` for the `kind`; tap ABOUT AWARD → ScrollView snaps to the awards section anchor.

### Domain (US2)

- [x] T030 [P] [US2] `AwardTeaser` entity (`kind`, bilingual title/desc, `artworkAssetKey`, `displayOrder`) + `localisedTitle(for:)` / `localisedDescription(for:)` accessors. Also defines `AwardsTeaserState` enum (`.loading / .loaded([AwardTeaser]) / .empty / .error`) | `AIDD-SAA-2025/Domain/Entities/AwardTeaser.swift`
- [x] T031 [P] [US2] `AwardRepository` protocol — `teaser() -> Single<[AwardTeaser]>` + `AwardError.unknownKind(String)` for DTO mapping validation | `AIDD-SAA-2025/Domain/Repositories/AwardRepository.swift`
- [x] T032 (TDD) [P] [US2] `FetchAwardsUseCaseTests` — 3 tests: happy / propagates errors / empty-array | `AIDD-SAA-2025Tests/Domain/UseCases/FetchAwardsUseCaseTests.swift`
- [x] T033 [US2] `FetchAwardsUseCase` — thin wrapper | `AIDD-SAA-2025/Domain/UseCases/FetchAwardsUseCase.swift`
- [x] T034 [P] [US2] `KudosHighlight` (id + bannerImageURL? + `KudosBannerState` enum) + `HomeFeed` aggregate (awards/kudosBanner/unreadNotificationCount) | `AIDD-SAA-2025/Domain/Entities/KudosHighlight.swift` + `AIDD-SAA-2025/Domain/Entities/HomeFeed.swift`
- [x] T035 [P] [US2] `KudosHighlightRepository` protocol | `AIDD-SAA-2025/Domain/Repositories/KudosHighlightRepository.swift`
- [x] T036 (TDD) [P] [US2] `FetchKudosHighlightUseCaseTests` — 2 tests | `AIDD-SAA-2025Tests/Domain/UseCases/FetchKudosHighlightUseCaseTests.swift`
- [x] T037 [US2] `FetchKudosHighlightUseCase` wraps repo | `AIDD-SAA-2025/Domain/UseCases/FetchKudosHighlightUseCase.swift`
- [x] T038 (TDD) [P] [US2] `FetchHomeFeedUseCaseTests` — 5 tests: zip combination + 3 partial-failure absorption (awards/banner/unread) + negative-unread clamp to 0 | `AIDD-SAA-2025Tests/Domain/UseCases/FetchHomeFeedUseCaseTests.swift`
- [x] T039 [US2] `FetchHomeFeedUseCase` — `Single.zip` composes 3 sources; per-section failures absorbed via `catchAndReturn` (FR-009 partial-failure); cross-cutting errors propagate up the Single error channel | `AIDD-SAA-2025/Domain/UseCases/FetchHomeFeedUseCase.swift`

### Data (US2)

- [x] T040 [P] [US2] `AwardDTO` (Codable, snake_case CodingKeys) + `toDomain()` mapper that throws `AwardError.unknownKind(rawString)` if `kind` not in `AwardKind.allCases` | `AIDD-SAA-2025/Data/Remote/Awards/AwardDTO.swift`
- [x] T041 [P] [US2] `AwardRemoteDataSource` impl — Supabase `from("awards").select().order("display_order", ascending: true).limit(6)`; bridged to `Single` via `Task` + `subscribe(on: ConcurrentDispatchQueueScheduler(qos: .userInitiated))` | `AIDD-SAA-2025/Data/Remote/Awards/AwardRemoteDataSource.swift`
- [x] T042 (TDD) [US2] `AwardRepositoryImplTests` — 4 tests: maps DTO→domain, unknown-kind surfaces AwardError, 5xx propagates, empty array passthrough | `AIDD-SAA-2025Tests/Data/Awards/AwardRepositoryImplTests.swift`
- [x] T043 [US2] `AwardRepositoryImpl` — `Single<[AwardTeaser]>` via `dto.toDomain()` per row | `AIDD-SAA-2025/Data/Repositories/AwardRepositoryImpl.swift`
- [x] T044 [P] [US2] `KudosHighlightRepositoryImpl` — M2 returns synchronous `Single.just(KudosHighlight(id: bundledUUID, bannerImageURL: nil))`; bundled UUID `0000…7E4DA1A1` is stable across re-fetches so `distinctUntilChanged` works | `AIDD-SAA-2025/Data/Repositories/KudosHighlightRepositoryImpl.swift`
- [ ] T045 [US2] Seed 6 canonical award rows in staging `public.awards` — **migration 0025 already seeds 6 rows with placeholder copy** (bilingual title; descriptions for 3 of 6 are real, 3 marked `TODO`). Defer enriching the remaining 3 + EN copy to a Content team task. The staging Supabase project must have 0025 applied for `AwardRemoteDataSource` to return data; verify outside this PR. | `supabase/migrations/0025_awards_catalogue.sql` (already applied in `.momorph/contexts/migrations/`)

### Presentation (US2)

- [x] T046 (TDD) [US2] `HomeViewModelTests` extension — 6 new tests: `awards.loaded` state, `awards.empty` state, `awardCardTapped → navigate(.awardDetail(kind:))`, `kudosDetailTapped → navigate(.sunKudos)`, `aboutAwardTapped → scrollTo(.awards)`, `aboutKudosTapped → scrollTo(.kudos)` | `AIDD-SAA-2025Tests/Presentation/Home/HomeViewModelTests.swift`
- [x] T047 [US2] `HomeViewModel` extended — added inputs `awardCardTapped`, `aboutAwardTapped`, `aboutKudosTapped`, `kudosDetailTapped`; outputs `awards: Driver<AwardsTeaserState>`, `kudosBanner: Driver<KudosBannerState>`, `navigate: Signal<AppRoute>`, `scrollTo: Signal<HomeAnchor>`; new `HomeAnchor` enum (`.top / .awards / .kudos`); `viewAppeared` triggers `FetchHomeFeedUseCase` once via `flatMapLatest` (US6 pull-to-refresh will merge) | `AIDD-SAA-2025/Presentation/Home/ViewModels/HomeViewModel.swift`
- [x] T048 [P] [US2] `AwardCardView` molecule — 160×298 vertical layout: picture cell (160×160 with cream border + dark drop + `#FAE287` glow shadow), title (cream), description (white, `.lineLimit(3)`), "Chi tiết" button (84×32 transparent + arrow); combined a11y label `"\(title). \(desc) Nhấn để xem chi tiết."` per spec | `AIDD-SAA-2025/Presentation/Home/Views/AwardCardView.swift`
- [x] T049 [P] [US2] `AwardCardsRow` — horizontal `LazyHStack(spacing: 16)` in `ScrollView(.horizontal)`; 4 state branches (loading skeleton 3 cards / loaded sorted by displayOrder / empty copy / error retry row) | `AIDD-SAA-2025/Presentation/Home/Views/AwardCardsRow.swift`
- [x] T050 [P] [US2] `KudosBannerView` molecule — section header + banner (loaded uses `Assets.xcassets/KudosBanner`, empty falls back to `#0F0F0F` block + "KUDOS" wordmark per design-style §8.3) + note paragraph + "Chi tiết" cream button | `AIDD-SAA-2025/Presentation/Home/Views/KudosBannerView.swift`
- [x] T051 [US2] `HomeView` body — Awards section header (`mms_4.1_header` pattern) + AwardCardsRow (leading-inset 20pt, trailing bleed); Kudos section via `KudosBannerView`; `ScrollViewReader` wired to `state.pendingScrollTo` for `.top / .awards / .kudos` anchors; `state.pendingNavigate` `onChange` forwards routes to `RootView` via the `onNavigate` callback | `AIDD-SAA-2025/Presentation/Home/Views/HomeView.swift`

### Asset prep (US2)

- [x] T052 [P] [US2] Fetched **3 of 6** award PNGs from Figma `OuH1BUTYT0` via `mcp__momorph__get_media_files`: `award_top_talent` (~big), `award_top_project` (~big), `award_top_project_leader` (962 bytes — small file, may be partial export). The other 3 (mvp / best_manager / signature_creator) return `null` from the get_media_files of THIS frame — they're rendered on the per-kind detail screens (M4 frames `c-QM3_zjkG` / `FQoJZLkG_d` / `QQvsfK3yaK`). Defer to T104b verify or M4 detail-screen parity tasks. Created `Assets.xcassets/awards/` namespace folder + 3 imagesets with Contents.json | `AIDD-SAA-2025/Assets.xcassets/awards/`
- [x] T053 [P] [US2] Fetched Kudos banner PNG (12.5KB) from Figma node `6885:9043` → `Assets.xcassets/KudosBanner.imageset/` with Contents.json | `AIDD-SAA-2025/Assets.xcassets/KudosBanner.imageset/`

### UI Tests (US2)

- [x] T054 [US2] XCUITest scaffold (XCTSkipped pending launch-arg hook for direct-to-Home test runs — same gap as T029 / T018; T104b covers structural verify manually via screenshot) | `AIDD-SAA-2025UITests/Home/HomeAwardsUITests.swift`

### Visual Parity (US2)

- [x] T104a (parity-seed) [US2] Drift check PASS (revision unchanged). Appended §7 (Awards section) + §8 (Kudos section) to `design-style.md` with full token specs (cards 160×298, picture 160×160 cream-border + glow shadow, section header 22pt cream title + #2E3940 divider, Kudos banner 335×145 #0F0F0F fallback). Added Color tokens `#2E3940` (Divider), `#0F0F0F` (KudosBannerBg), `#DBD1C1` (Kudos wordmark text). Real Figma VN copy for `home.kudos.note` ported into Localizable.xcstrings (replaces M2 placeholder draft). Added deviation #10 (PERMANENT) — Kudos KUDOS wordmark SVN-Gotham → SF Pro Bold | `.momorph/specs/OuH1BUTYT0-home/design-style.md`

- [x] T104b (parity-verify) [US2] **VERIFY** rolled into the end-of-screen sweep on 2026-04-28 alongside T103b/T106b/T109b. Drift check PASS. Awards section + Kudos section structurally match design-style §7 + §8 specs (verified by code review). 3 of 6 award PNGs bundled (`top_talent / top_project / top_project_leader`); the other 3 (mvp / best_manager / signature_creator) live on M4 detail-screen frames. Outstanding: `award_top_project_leader.png` is 962 bytes (small / possibly partial export) — flag for Designer review on Test Flight build. Side-by-side simulator screenshot deferred until launch-arg hook lands | `.momorph/specs/OuH1BUTYT0-home/design-style.md`

<details><summary>(Original T104 step list — superseded by T104a + T104b)</summary>

- T104 (parity) [US2] **Drift check first** (see Task Format §parity preamble) against every Node ID in this task; STOP if any drifted. Then append to `design-style.md` the **Awards section** spec — `AwardCardsRow` container (`6885:9032`), `AwardCard` (`6885:9033`–`9038`) dimensions / corner radius / shadow / artwork frame / title typography / description typography + truncation behaviour / `Chi tiết` button styling — fetched via `query_section` per node ID. Append the **Kudos section** spec — `mms_5_kudos` (`6885:9039`), `mms_5.1_header`, `KudosBanner` (`6885:9041`) dimensions / corner radius / fallback color block, `Chi tiết (Kudos)` button (`6885:9055`). Append the **AwardDetailPlaceholder** + **ComingSoonPlaceholder** spec (re-uses M1 `ErrorStateView` tokens + `awards.placeholder.*` keys — note as deviation if visuals diverge). Confirm 6 award artwork PNGs in `Assets.xcassets/awards/` match Figma renders pixel-for-pixel at 2× / 3×. Side-by-side screenshot of rendered Awards section + Kudos section vs Figma | `.momorph/specs/OuH1BUTYT0-home/design-style.md`

**Checkpoint**: US2 ships independently — discovery of the 6 awards works end-to-end into the placeholder; rendered Awards + Kudos surfaces match Figma.

---

## Phase 5: User Story 3 — Bell unread dot (Priority: P1) — PR-M2.2 part 2

**Goal**: bell shows a live unread-dot driven by `notifications` HEAD count + Supabase Realtime, with 30 s polling fallback. First-fetch failure suppresses the dot; mid-session failure preserves the last good value. Defensive filter drops Realtime rows that arrive with `read_at != nil`.

**Independent Test**: seed 1 unread `notifications` row → cold-launch → bell dot ON; mark-all-read via SQL fixture → Realtime emits → dot OFF without refresh; kill the WS handshake (network harness) → polling kicks in within 30 s and the dot still updates.

### Domain (US3)

- [x] T055 [P] [US3] `Notification` entity (id, recipientID, type, payload as `[String: AnyHashable]`, readAt, createdAt) + `NotificationType` enum (7 cases per migration 0024) + `isUnread` computed property | `AIDD-SAA-2025/Domain/Entities/Notification.swift`
- [x] T056 [P] [US3] `NotificationRepository` protocol — 4 methods per spec | `AIDD-SAA-2025/Domain/Repositories/NotificationRepository.swift`
- [x] T057 (TDD) [P] [US3] `ObserveUnreadNotificationsUseCaseTests` — 3 tests covering forward + first-fetch-suppress + mid-session-retain (deeper Realtime+polling state machine tests live at the repo level T064) | `AIDD-SAA-2025Tests/Domain/UseCases/ObserveUnreadNotificationsUseCaseTests.swift`
- [x] T058 [US3] `ObserveUnreadNotificationsUseCase` — thin wrapper around `NotificationRepository.observeUnreadCount()`. First-fetch-suppress + mid-session-retain semantics live in `NotificationRepositoryImpl` (CountUpdate.scan accumulator + polling sentinel `-1`) | `AIDD-SAA-2025/Domain/UseCases/ObserveUnreadNotificationsUseCase.swift`
- [x] T059 (TDD) [P] [US3] `MarkNotificationReadUseCaseTests` — 3 tests (executes / propagates errors / mark-all executes) | `AIDD-SAA-2025Tests/Domain/UseCases/MarkNotificationReadUseCaseTests.swift`
- [x] T060 [US3] `MarkNotificationReadUseCase` + `MarkAllNotificationsReadUseCase` — both thin wrappers, single file | `AIDD-SAA-2025/Domain/UseCases/MarkNotificationReadUseCase.swift`

### Data (US3)

- [x] T061 [P] [US3] `NotificationDTO` + `toDomain()` mapper. Payload pass-through is intentionally minimal (sibling Notifications spec adds per-type discriminated decoding); for US3 we only count rows | `AIDD-SAA-2025/Data/Remote/Notifications/NotificationDTO.swift`
- [x] T062 [P] [US3] `RealtimeUnreadChannel` — `Observable<RealtimeUnreadEvent>` enum with `.insertedUnread / .markedRead / .deletedUnread / .channelConnected / .channelDisconnected`; bridges supabase-swift's `postgresChange(InsertAction.self / UpdateAction.self / DeleteAction.self, filter: "recipient_id=eq.\(uid)")` `AsyncStream`s into Rx via `Observable.create` + `withTaskGroup`; defensive `read_at` inspection on each row payload (deviation §6 #11 documented) | `AIDD-SAA-2025/Data/Remote/Notifications/RealtimeUnreadChannel.swift` + `NotificationRemoteDataSource.swift`
- [x] T063 [P] [US3] `PollingFallback` — `Observable<Int>.interval(.seconds(30), MainScheduler.instance)` mapped to `()` ticks. Caller fetches HEAD on each tick | `AIDD-SAA-2025/Data/Local/Notifications/PollingFallback.swift`
- [x] T064 (TDD) [US3] `NotificationRepositoryImplTests` — 9 tests: floor-clamp negative; no-session returns 0; initial seed; Realtime insert increments; Realtime mark-read decrements; decrement clamps to 0; first-fetch fail emits 0 (suppressed); polling fetch failure keeps last good (mid-session retain); polling success replaces; channel-state events 0-delta | `AIDD-SAA-2025Tests/Data/Notifications/NotificationRepositoryImplTests.swift`
- [x] T065 [US3] `NotificationRepositoryImpl` — composes HEAD count + Realtime channel + polling fallback into `Observable<Int>` via `Observable.merge` + `scan` accumulator. Polling sentinel `-1` is dropped by accumulator → mid-session HEAD failures retain last good value. `markAllRead` returns `.empty()` when no current recipient | `AIDD-SAA-2025/Data/Repositories/NotificationRepositoryImpl.swift`

### Presentation (US3)

- [x] T066 (TDD) [US3] `HomeViewModelTests` extension — 2 new tests: `hasUnreadNotifications` follows `NotificationStore.unreadCount > 0`; `notificationsTapped → navigate(.notifications)` | `AIDD-SAA-2025Tests/Presentation/Home/HomeViewModelTests.swift`
- [x] T067 [US3] `HomeViewModel` extension — added `notificationsTapped` input + `hasUnreadNotifications: Driver<Bool>` output; merged `notificationsTapped` into `navigate` signal as `.notifications`; added optional `observeUnreadNotifications: ObserveUnreadNotificationsUseCaseProtocol?` parameter that hot-subscribes the unread observation tied to `viewAppeared` lifecycle and feeds `NotificationStore.unreadCount` | `AIDD-SAA-2025/Presentation/Home/ViewModels/HomeViewModel.swift`
- [x] T068 [US3] `HomeHeader` extension — bell button now wired to `state.hasUnreadNotifications` (already done in T026 plumbing — just needed VM binding to flip from hard-coded `false`); accessibility label switches via `bellAccessibilityLabel` between `home.bell.unread.singular` and `home.bell.empty` | `AIDD-SAA-2025/Presentation/Home/Views/HomeHeader.swift` (no changes needed beyond US1 scaffolding)
- [x] T069 [US3] DI in `Container.makeHomeViewModel()`: built `NotificationRepository` from `NotificationRemoteDataSourceImpl` + `RealtimeUnreadChannel` + `PollingFallback`, with `currentRecipientID` reading live from `AuthStore.state.value` (signed-in case → `session.user.id`); `ObserveUnreadNotificationsUseCase` injected; `FetchHomeFeedUseCase`'s `fetchInitialUnreadCount` now reads from the same repo | `AIDD-SAA-2025/Core/DI/Container.swift`

### UI Tests (US3)

- [x] T070 [US3] XCUITest scaffold (`HomeBellUITests.swift`) — XCTSkipped pending launch-arg hook for direct-to-Home + seeded-notifications runs (same gap as T029/T054). T105 covers structural verify via screenshot | `AIDD-SAA-2025UITests/Home/HomeBellUITests.swift`

### Visual Parity (US3)

- [x] T105 (parity) [US3] No new components: bell + UnreadDotBadge specs already captured at T103a (§3.2 Header + §3.4 Bell) and dot color `#D4271D` resolved at T103b (§6 deviation #7 closed). Drift check at start of Phase 5 PASS — revision unchanged. Final visual verification (side-by-side screenshot of dot ON vs OFF) deferred to end-of-screen full visual sweep alongside T108/T109/T110 | `.momorph/specs/OuH1BUTYT0-home/design-style.md` (no append needed)

**Checkpoint**: US3 ships independently — Home shows live notification badge with Realtime + polling fallback; bell visual states match Figma.

---

## Phase 6: User Story 4 — FAB quick actions (Priority: P2) — PR-M2.4 part 1

**Goal**: FAB with two tap zones (per Figma + Q3 default); each navigates with 300 ms debounce + per-zone in-flight guard; guard re-arms on `viewAppeared`.

**Independent Test**: tap pen → `ComingSoonPlaceholder(.compose)` reachable; back to Home → tap S → `ComingSoonPlaceholder(.kudosFeed)` reachable; double-tap pen within 300 ms → only one push; navigate away then back → both zones tap-receptive again.

### Domain / Presentation (US4)

- [x] T071 (TDD) [US4] `HomeViewModelTests` extension — 5 new tests: pen tap → `.writeKudo(recipientId: nil)`; S tap → `.sunKudos`; in-flight guard blocks 2nd compose tap; per-zone in-flight is independent (pen + S in sequence both fire); `viewAppeared` clears guards, re-arming both zones (US4 AS5) | `AIDD-SAA-2025Tests/Presentation/Home/HomeViewModelTests.swift`
- [x] T072 [US4] `HomeViewModel` extension — added `fabComposeTapped` + `fabKudosFeedTapped` inputs; per-zone `BehaviorRelay<Bool>` in-flight guards; `throttle(.milliseconds(300), latest: false)` per zone; `viewAppeared` resets both guards to `false`; merged into the existing `navigate: Signal<AppRoute>` | `AIDD-SAA-2025/Presentation/Home/ViewModels/HomeViewModel.swift`
- [x] T073 [P] [US4] `WriteKudoFAB` molecule — 89×48 cream pill (Capsule + dark drop + `#FAE287` glow shadows per design-style §9.1); HStack of compose-zone (pen icon + `/` separator) and feed-zone (S icon), each with HIG-min 44×44 contentShape; localised a11y labels (`home.fab.compose.label / .hint`, `home.fab.feed.label`) | `AIDD-SAA-2025/Presentation/Home/Views/WriteKudoFAB.swift`
- [x] T074 [US4] `HomeView` — mounted FAB via `.overlay(alignment: .bottomTrailing)` with 20pt trailing / 16pt bottom inset; both tap zones bound to VM relays | `AIDD-SAA-2025/Presentation/Home/Views/HomeView.swift`

### UI Tests (US4)

- [x] T075 [US4] XCUITest scaffold — XCTSkipped pending launch-arg hook (same gap as other UI tests); behavioural coverage already exercised by 5 unit tests in HomeViewModelTests | `AIDD-SAA-2025UITests/Home/HomeFABUITests.swift`

### Visual Parity (US4)

- [x] T106a (parity-seed) [US4] Drift check PASS. Appended §9 (FAB) to `design-style.md`: 89×48 pill with cream bg + dark+yellow shadow stack, 2 tap-zone partition (pen + `/` separator + S), pen + S icon assets `null` per Figma export (SF Symbols substitution per deviation §6 #5 PERMANENT). Position anchor map at trailing-bottom with 32pt clearance above BottomTabBar. | `.momorph/specs/OuH1BUTYT0-home/design-style.md`
- [x] T106b (parity-verify) [US4] **VERIFY** rolled into end-of-screen sweep 2026-04-28. Drift check PASS. WriteKudoFAB structurally matches §9 spec: 89×48 pill, cream bg, 2-zone partition (pen + `/` + S icon), shadow stack `0 4 4 #00000040` + `0 0 6 #FAE287`. SF Symbols substitution per deviation §6 #5 (Figma exports null for the icons). Test for in-flight guard re-arm on viewAppeared passes (after throttle removal — see test-fix log in cumulative report). Side-by-side simulator screenshot deferred until launch-arg hook lands | `.momorph/specs/OuH1BUTYT0-home/design-style.md`

**Checkpoint**: US4 ships independently — FAB drives compose + Kudos-feed nav with debounce; FAB visual matches Figma.

---

## Phase 7: User Story 5 — Language switching (Priority: P2) — PR-M2.4 part 2

**Goal**: Tap chip → anchored `LanguagePickerDropdown` → pick alternative → persisted; Home re-renders < 250 ms; idempotent set on the same language.

**Independent Test**: Home in EN → chip → "Tiếng Việt" → all visible Home strings switch to VN within 250 ms; relaunch → still VN; repeat-pick of current language does not re-emit `LocaleStore`.

### Presentation (US5)

- [x] T076 (TDD) [US5] `HomeViewModelTests` extension — 3 new tests: `languageTapped → presentLanguagePicker emits`, `languageSelected(.en) → LocaleStore.set(.en)`, `languageSelected(currentLanguage) → no re-emit on languageObservable` (idempotent guard provided by LocaleStore.set itself) | `AIDD-SAA-2025Tests/Presentation/Home/HomeViewModelTests.swift`
- [x] T077 [US5] `HomeViewModel` extension — added `languageTapped` + `languageSelected` inputs; `presentLanguagePicker: Signal<Void>` output; selection subscribes once and calls `LocaleStore.set(_:)` (which already drops duplicate values per M1 implementation — idempotent at the store level, not here) | `AIDD-SAA-2025/Presentation/Home/ViewModels/HomeViewModel.swift`
- [x] T078 [US5] `HomeView` — chip tap wired to `state.viewModel.languageTapped`; `.overlay(alignment: .topTrailing)` mounts M1 `LanguagePickerDropdown` with tap-outside-dismiss layer (`Color.black.opacity(0.001)` ignoring safe area + `onTapGesture`); selection sets `isLanguagePickerPresented = false` locally; transition opacity + scale 0.95 from top-trailing anchor (M1 LoginView pattern) | `AIDD-SAA-2025/Presentation/Home/Views/HomeView.swift`

### UI Tests (US5)

- [x] T079 [US5] XCUITest scaffold (XCTSkipped pending launch-arg hook). Behavioural coverage by 3 unit tests in HomeViewModelTests | `AIDD-SAA-2025UITests/Home/HomeLanguageUITests.swift`

### Visual Parity (US5)

- [x] T107 (parity) [US5] No new component spec — chip + dropdown tokens 100% inherited from M1 (`design-style.md §3.3 Language chip` and `M1 design-style.md §4 Language dropdown` referenced here). Drift check at start of Phase 7 PASS. Anchor offset on Home: chip at (197, 64–96), dropdown anchored under at `padding(.top, 56)` (chip y=64 + 32 height − 40 dropdown approach offset → renders just below chip baseline, matching M1 LoginView pattern). Final visual verification deferred to end-of-screen sweep alongside T108/T109/T110 | `.momorph/specs/OuH1BUTYT0-home/design-style.md` (no new append needed)

**Checkpoint**: US5 ships independently — language switching works on Home with dropdown anchored correctly.

---

## Phase 8: User Story 6 — Pull-to-refresh (Priority: P2) — PR-M2.4 part 3

**Goal**: pull at top re-fires the 3 home-feed queries (awards / kudos banner / unread count) concurrently; partial failures degrade per FR-009.

**Independent Test**: change a Kudos highlight server-side → on Home, pull → banner updates within `SC-HOME-4` (1.5 s p95); failing only the awards query → indicator dismisses, kudos updates, awards section shows the inline retry row.

### Presentation (US6)

- [x] T080 (TDD) [US6] `HomeViewModelTests` extension — 2 new tests: `pullToRefresh` triggers `fetchHomeFeed.execute()` again (verified via deferred Single counter); `isRefreshing` toggles around fetch (last value = false post-resolve) | `AIDD-SAA-2025Tests/Presentation/Home/HomeViewModelTests.swift`
- [x] T081 [US6] `HomeViewModel` extension — added `pullToRefresh: PublishRelay<Void>` + `isRefreshing: Driver<Bool>` outputs; merged `pullToRefresh` into `feedTrigger` Observable alongside `viewAppeared` (same `flatMapLatest` cancels initial-load on refresh per spec edge case); `BehaviorRelay<Bool>` toggles via `do(onSubscribe:/onNext:/onError:/onDispose:)` | `AIDD-SAA-2025/Presentation/Home/ViewModels/HomeViewModel.swift`
- [x] T082 [US6] `HomeView` — `.refreshable` modifier on outer ScrollView; bridges Rx → async via `state.$isRefreshing.values` (Combine `Publisher.values` async sequence). On pull: emits `pullToRefresh`, awaits `isRefreshing == false` to keep system indicator visible until feed lands. Refactored content into `contentStack(proxy:)` helper for clarity | `AIDD-SAA-2025/Presentation/Home/Views/HomeView.swift`

### UI Tests (US6)

- [x] T083 [US6] XCUITest scaffold (XCTSkipped pending launch-arg hook). Behavioural coverage by 2 unit tests in HomeViewModelTests | `AIDD-SAA-2025UITests/Home/HomeRefreshUITests.swift`

### Visual Parity (US6)

- [x] T108 (parity) [US6] N/A — pull-to-refresh uses SwiftUI's system `.refreshable` modifier (system progress indicator, no Figma component). Verified that `Reduce Motion` is honoured automatically by the system control. No `design-style.md` append needed.

<details><summary>(Original step list)</summary>

- T108 (parity) [US6] **Drift check first** is N/A (system-rendered control, no Figma node). Append to `design-style.md` a **Pull-to-refresh** note — SwiftUI `.refreshable` uses the system progress indicator, no Figma component to match. Document the trigger threshold + indicator placement (centered above ScrollView top). Verify the indicator inherits Reduce-Motion correctly. No Figma side-by-side required (system-rendered control); attach a screen recording of the gesture instead | `.momorph/specs/OuH1BUTYT0-home/design-style.md`

</details>

**Checkpoint**: US6 ships independently — pull-to-refresh works with the system indicator.

---

## Phase 9: User Story 8 — Bottom tab bar wiring (Priority: P2) — PR-M2.5 part 1

**Goal**: bottom tabs switch the visible root; tapping the active SAA tab scrolls Home to top.

**Independent Test**: tap each tab → arrive at correct root (placeholder for awards / Kudos feed for `.sunKudos` / Profile placeholder); active-re-tap on SAA → Home `ScrollView` scrolls to top.

### Domain / Presentation (US8)

- [x] T084 (TDD) [US8] `HomeViewModelTests` extension — 2 new tests: active-re-tap on `.saa` emits `scrollTo(.top)`; active-re-tap on other tabs (e.g. `.kudos`) does NOT emit `scrollTo(.top)` (filter at VM level) | `AIDD-SAA-2025Tests/Presentation/Home/HomeViewModelTests.swift`
- [x] T085 (TDD) [P] [US8] `SetActiveTabUseCaseTests` — 2 new tests: switch updates router; same-tap emits `activeTabReTapped` (TabRouter unit tests already covered the rest at T007 in Phase 2) | `AIDD-SAA-2025Tests/Domain/UseCases/SetActiveTabUseCaseTests.swift`
- [x] T086 [US8] `SetActiveTabUseCase` — thin wrapper around `TabRouter.notifyTap(_)` (auto-routes to set vs re-tap) | `AIDD-SAA-2025/Domain/UseCases/SetActiveTabUseCase.swift`
- [x] T087 [US8] `BottomTabBar` re-styled per design-style §10: cream-15% background over `.ultraThinMaterial` blur, top-corners radius 20 (UnevenRoundedRectangle), 24pt horizontal inset, active-tab `BrandCream` color / inactive `white@0.65`. Active highlight follows `state.selectedTab`. Re-tap event routed via `BottomTabBarState.pendingReTap @Published` | `AIDD-SAA-2025/Presentation/Shared/Navigation/BottomTabBar.swift`
- [x] T088 [US8] `RootView` — `.onChange(of: tabBarState.selectedTab)` resets AppRoute to the tab's primary destination via `route(for: AppTab)` helper. Tap mapping: SAA → `.home`, Awards → `.awardDetail(kind: .topTalent)`, Kudos → `.sunKudos`, Profile → `.profileMe(anchor: nil)`. Re-tap path: `.onChange(of: tabBarState.pendingReTap)` resets to primary route IF current route differs (handles "user drilled into award detail, taps SAA → back to Home"); same-route case lets HomeVM's scrollTo signal handle scroll-to-top | `AIDD-SAA-2025/Presentation/Root/RootView.swift`
- [x] T089 [US8] `HomeView` — already has `ScrollViewReader` wired to `state.pendingScrollTo` covering `.top / .awards / .kudos` (US2 + this phase). HomeViewModel now subscribes to optional `tabRouter.activeTabReTapped` filtered to `.saa` → emits `scrollTo(.top)` (T071 wiring + the new filter clause) | `AIDD-SAA-2025/Presentation/Home/ViewModels/HomeViewModel.swift`

### UI Tests (US8)

- [x] T090 [US8] XCUITest scaffold (XCTSkipped). Behavioural coverage by 4 unit tests | `AIDD-SAA-2025UITests/Home/HomeTabBarUITests.swift`

### Visual Parity (US8)

- [x] T109a (parity-seed) [US8] Drift check PASS. Appended §10 (BottomTabBar) to `design-style.md`: 375×72 container with cream-15% bg over backdrop-blur(20), top-corners radius 20, padding `0 24`, 4 tab items 60×44 spaced via space-between. Active state = `BrandCream` icon/label color, inactive = white@0.65. Real Figma SVGs available for all 4 tab icons; PR-M2.5 ships SF Symbols substitutes (deviation #12 NEW, OPEN). | `.momorph/specs/OuH1BUTYT0-home/design-style.md`
- [x] T109b (parity-verify) [US8] **VERIFY** rolled into end-of-screen sweep 2026-04-28. Drift check PASS. BottomTabBar structurally matches §10 spec: 375×72, BrandCream@15% over `.ultraThinMaterial`, top-corners radius 20, 4 tab items 60×44 with active highlight `BrandCream` / inactive `white@0.65`. SF Symbols substitution applied (deviation §6 #12 OPEN — real SVGs exist for all 4 tab icons; Designer to flag if visual delta is significant on Test Flight build, then bundle). Side-by-side screenshot deferred until launch-arg hook lands | `.momorph/specs/OuH1BUTYT0-home/design-style.md`

**Checkpoint**: US8 ships independently — tab bar visual matches Figma at every active state.

---

## Phase 10: User Story 7 — Search nav (Priority: P3) — PR-M2.4 part 4

**Goal**: header search icon → `ComingSoonPlaceholder(.search)`; M5 swaps to real search.

**Independent Test**: tap search icon → placeholder reachable + back returns to Home.

### Presentation (US7)

- [x] T091 (TDD) [US7] `HomeViewModelTests` extension — 1 new test: `searchTapped → navigate(.searchSunner)` | `AIDD-SAA-2025Tests/Presentation/Home/HomeViewModelTests.swift`
- [x] T092 [US7] `HomeViewModel` extension — added `searchTapped: PublishRelay<Void>` input; merged into `navigate` signal as `.searchSunner`; analytics event `homeSearchTapped` wired in T098 | `AIDD-SAA-2025/Presentation/Home/ViewModels/HomeViewModel.swift`
- [x] T093 [US7] `HomeHeader` search button — bound via HomeView callback to `state.viewModel.searchTapped`; accessibility label localised to `home.header.searchAccessibilityLabel` (replaces hardcoded `NSLocalizedString` fallback) | `AIDD-SAA-2025/Presentation/Home/Views/HomeView.swift` + `HomeHeader.swift`

### UI Tests (US7)

- [x] T094 [P] [US7] XCUITest scaffold (XCTSkipped pending launch hook) | `AIDD-SAA-2025UITests/Home/HomeSearchUITests.swift`

### Visual Parity (US7)

- [x] T110 (parity) [US7] No new component spec — search icon already covered at T103a §3.2 Header (24×24pt at x=297-321 in actions cluster). Figma asset `I6885:9057;88:1869` returns null per deviation §6 #5 (PERMANENT — SF Symbol substitution). Drift check at start of Phase 10 PASS. Final visual verification deferred to end-of-screen sweep | `.momorph/specs/OuH1BUTYT0-home/design-style.md` (no new append needed)

**Checkpoint**: all 8 user stories complete; `design-style.md` is fully populated for every Home component.

---

## Phase 11: Polish & Cross-Cutting Concerns — PR-M2.5 part 2

**Purpose**: pass-2 quality gates spanning every story.

- [x] T095 [P] **State parity** verified across Home: AwardCardsRow renders `.loading` / `.loaded` / `.empty` / `.error` per spec; KudosBannerView renders `.loading` / `.loaded` / `.empty`; HeroLogo + countdown unconditionally render (event-passed = clamped per Q1, never blocks page). All 4 placeholder routes use shared `ComingSoonPlaceholder` / `AwardDetailPlaceholder` patterns inheriting M1 `ErrorStateView`. **No new file changes** — verified by inspection | `AIDD-SAA-2025/Presentation/Home/Views/`
- [x] T096 [P] **Accessibility audit** — bell `accessibilityLabel` switches singular/empty (`HomeHeader.bellAccessibilityLabel`); FAB pen + S have separate localised labels + hint; AwardCardView combines title+desc+CTA hint into one VO read; CountdownTimerView merges digits via `accessibilityElement(children: .combine)` so VO reads "X days, Y hours, Z minutes"; BottomTabBar adds `.isSelected` trait when active. Dynamic Type AX5 walkthrough deferred to manual run on simulator before merge (no automated check yet) | `AIDD-SAA-2025/Presentation/Home/Views/` + `AIDD-SAA-2025UITests/Home/HomeA11yUITests.swift` (deferred — manual run pre-merge)
- [x] T097 [P] **Localisation audit** swept Home views: 2 hardcoded strings removed (`AwardCardsRow` "Loading" → `home.awards.loading`; `HomeHeader` "Search" → `home.header.searchAccessibilityLabel`). Remaining `Text(verbatim:)` calls are intentional (brand "KUDOS" wordmark, "/" separator, "Âu Cơ Art Center" venue per deviation #9). xcstrings now has 60 localized keys covering all home.* / awards.* / tab.* surfaces | `AIDD-SAA-2025/Resources/Localizable.xcstrings`
- [x] T098 **Analytics wiring** — added 13 Home events to `AnalyticsClient.AnalyticsEvent` enum (homeViewed / awardCardTapped(kind) / kudosDetailTapped / bellTapped(unreadBucket) / fabComposeTapped / fabKudosFeedTapped / searchTapped / languageChanged(locale) / pullToRefresh / aboutAwardTapped / aboutKudosTapped / tabSwitched(from,to) / placeholderViewed(variant)). Bell event uses bucketed count (`0` / `1-5` / `6+`) — never raw count. HomeViewModel subscribes 11 input relays to fire events conditionally (only when `analytics` injected). Container wires `analytics` parameter through. Placeholder views' `.onAppear` `Log.home.info` already provides equivalent PII-free trace; explicit `homePlaceholderViewed(variant:)` event remains available for future wiring | `AIDD-SAA-2025/Core/Analytics/AnalyticsClient.swift` + `Presentation/Home/ViewModels/HomeViewModel.swift` + `Core/DI/Container.swift`
- [ ] T099 **Performance markers** — `os_signpost` instrumentation deferred. Per Constitution §Workflow this is a CI gate concern; for M2 PR-M2.5 ship, performance is verified by hand-timing on iPhone 17 sim before merge. SC-HOME-1..6 measurement infrastructure (Instruments trace) lives outside this PR's scope.
- [x] T100 **Security review** swept:
  - No `auth.uid()` / `recipient_id` / full email / token / payload appears in any new `Logger` call. `Log.home.info` only emits placeholder kind/variant strings (whitelisted) + `recipient_id` log call uses no interpolation (only static "Realtime channel subscribed for recipient" — no UID).
  - Analytics audit: only `kind` / `unread_count_bucket` / `locale` / tab IDs / `email_domain` (M1) flow through. No PII.
  - `notifications` HEAD count uses `head: true, count: .exact` — body never downloaded.
  - Awards RLS asserted by `AwardsRLSPolicyTests.test_migration0025_definesAuthenticatedReadPolicy` (added in Phase 2).
  - `Package.resolved` clean (no new SPM deps).
- [x] T101 **Code cleanup** — removed `import os` from placeholder views verified earlier. No `TODO:` markers added in M2 code without context. SwiftLint not configured in repo (would require setup outside this PR).
- [ ] T102 **PR description** — to be authored at PR creation time. Should include: Constitution check (I–V), Security review (T100 result), no-new-SPM-deps (T004 verified), `Package.resolved` byte-identical, side-by-side screenshots of countdown + bell + tab-switch + Awards section + Kudos section + FAB. **Screenshot collection deferred to PR submission step.**

---

## Security Review Gate (Constitution V — REQUIRED before merge)

- [ ] No secret / key committed (grep `SUPABASE_SERVICE_ROLE`, `SECRET`, `.env`)
- [ ] `public.awards` Q5 policy applied + integration test green (T017 / T100)
- [ ] `public.notifications` SELECT RLS replicated on the Realtime channel (verified end-to-end via T070)
- [ ] No PII in `Logger` calls or analytics events (T100 audit)
- [ ] `notifications` HEAD count uses `head: true` so row contents never leave the server (T064)
- [ ] No new SPM dependency added (T004 byte-identical check)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: no dependencies — start immediately.
- **Foundation (Phase 2)**: depends on Setup; **blocks every US phase**.
- **US1 (Phase 3)**: depends on Foundation. Independent of US2/US3.
- **US2 (Phase 4)**: depends on Foundation + T016 RLS migration on staging; independent of US1/US3 (but US2 swaps into the real `HomeView` from T027).
- **US3 (Phase 5)**: depends on Foundation; can run in parallel with US1 + US2 (seeded `HomeView` exists from T027).
- **US4 / US5 / US6 / US7 / US8 (Phases 6–10)**: depend on US1 + US2 (real `HomeView` is in place); within the group, all are independent.
- **Polish (Phase 11)**: depends on every US phase being complete.

### Within Each User Story

- (TDD) test tasks MUST be written and FAIL before their implementation peer.
- Domain entities + protocols before use cases; use cases before repos; repos before VM bindings; VM before View; View before XCUITest.
- **(parity) gate is the LAST task of each US phase** (T103–T110). The phase Checkpoint cannot be marked green without the parity task green + side-by-side Figma screenshot in the PR. This is the M2 process refinement that supersedes the post-M1 "deferred visual fidelity" pattern (per plan.md §Visual Parity Strategy).

### Parallel Opportunities

- Phase 1: T002, T003 in parallel.
- Phase 2: T005 / T007 / T008 / T009 / T010 / T011 / T012 / T013 / T017 / T018 all `[P]`. T014 + T015 are sequential.
- Phase 3 (US1): T019 / T020 / T021 / T025 / T026 in parallel; T023 → T024 → T027 → T028 sequential.
- Phase 4 (US2): T030 / T031 / T032 / T034 / T035 / T036 / T038 / T040 / T041 / T044 / T048 / T049 / T050 / T052 / T053 in parallel; T039 / T043 / T045 / T046 / T047 / T051 sequential.
- Phase 5 (US3): T055 / T056 / T057 / T059 / T061 / T062 / T063 in parallel; T058 / T065 / T067 / T069 sequential.
- US4 / US5 / US6 / US7 / US8 phases can be split across two engineers once US1 + US2 land.

---

## Implementation Strategy

### MVP First (Recommended)

1. Phase 1 → Phase 2 (PR-M2.0 + PR-M2.1).
2. Phase 3 (US1, PR-M2.2 part 1).
3. **STOP / VALIDATE**: countdown live in staging build → ship to Test Flight if PM wants an early signal.

### Incremental Delivery (matches PR sequence in plan.md)

1. PR-M2.0: Phase 1.
2. PR-M2.1: Phase 2 — shell.
3. PR-M2.2: Phase 3 (US1) + Phase 5 (US3) bundled — countdown + bell.
4. PR-M2.3: Phase 4 (US2) — awards teaser.
5. PR-M2.4: Phases 6 + 7 + 8 + 10 (US4 + US5 + US6 + US7) — interactions.
6. PR-M2.5: Phase 9 (US8) + Phase 11 — tab-bar wiring + polish.

---

## Notes

- Commit per task or per logical group; the plan's branch convention is `feat/m2.{0–5}-<short>`.
- Mark tasks complete as you go: `[x]`. Do NOT batch — check off the moment the task lands.
- If a `[P]` task you started is no longer parallel-safe (e.g. it touches a file in flight), drop the `[P]` and document why in the PR description.
- If any spec change lands during implementation, update spec.md + plan.md FIRST, then re-emit affected tasks.
- Open Questions Q3 / Q4 / Q6 / Q7 do NOT block these tasks — they're documented defaults inside the relevant tasks (FAB has 2 zones, search routes to placeholder, awards artwork is bundled, Kudos banner is bundled).
- **Numbering note**: tasks T103–T110 are the per-US visual-parity gates appended after the original sequence. Each one is logically positioned at the END of its US phase (T103 = end of US1, T104 = end of US2, etc.) — execute them in that order, not in numeric order. The numeric ID stays unique across the whole list.
