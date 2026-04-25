# Screen: [iOS] Sun*Kudos_Search Sunner

## Screen Info

| Property | Value |
|----------|-------|
| **Figma Frame ID** | `3jgwke3E8O` (node `6891:21272`) |
| **Figma Link** | https://momorph.ai/files/9ypp4enmFmdK3YAFJLIu6C/screens/3jgwke3E8O |
| **Screen Group** | Shared UI / Sun\*Kudos cluster |
| **Platform** | iOS (SwiftUI) |
| **Status** | discovered (with 1 fold-in UI state) |
| **Discovered At** | 2026-04-24 |
| **Last Updated** | 2026-04-24 |

---

## Description

`[iOS] Sun*Kudos_Search Sunner` is the **app-wide Sunner search
screen** — reached from the 🔍 icon in the shared `HomeHeader`, from
the `[iOS] Sun*Kudos` Spotlight Board inline search, and potentially
from Profile headers. It has two modes:

1. **Default / empty state** (this parent frame): the search bar is
   empty; the screen shows a **"Recent"** heading and a list of recent
   searches, each with a close (X) button to remove from history.
2. **Active query** (fold-in: `[iOS] Sun*Kudos_Searching` `hldqjHoSRH`):
   the user has typed into the search bar; the screen shows live
   results (filtered by `full_name ILIKE %q%`). "Recent" heading and
   close buttons disappear; rows become tappable (no X).

Tapping a row — in either mode — navigates to that Sunner's profile
(`[iOS] Profile người khác`, or `[iOS] Profile bản thân` if the row
happens to match the current user).

Fold-in detail below covers the active-query state and its brief
loading sub-state.

---

## Navigation Analysis

### Incoming Navigations (From)

| Source | Trigger | Condition |
|--------|---------|-----------|
| `[iOS] Home` | Tap 🔍 search icon in the shared `HomeHeader` | Always — primary entry point |
| `[iOS] Sun*Kudos` (Spotlight Board) | Tap inline "Tìm kiếm sunner" input | In-board search → navigates here |
| `[iOS] Profile bản thân` / `Profile người khác` | Tap 🔍 search icon | Same shared header |
| Deep link | `app://search?q=<term>` | Any time — optional prefill |

### Outgoing Navigations (To)

| Target | Trigger Element | Node ID | Confidence | Notes |
|--------|-----------------|---------|------------|-------|
| (previous screen) | Back Icon | `6891:21281` | High | Standard pop |
| `[iOS] Profile người khác` (`bEpdheM0yU`) | Tap a result row (recent OR active query) | `6891:22087` / `6891:22109` / `6891:22142` / `6891:22145` | High | Pass `userId`; router rewrites to `profile/me` if `userId == auth.uid()` |
| (stay, remove from history) | Tap close (X) on a Recent row | `6891:22103` / `6891:22110` | High | Delete from recent-search cache; row animates out |
| "View all" — unclear destination | Tap "View all" next to "Recent" heading | `6891:22081` | Low | Likely opens a dedicated full history screen; TBC during `/momorph.specs`. v1 implementation may simply expand the list inline until product confirms. |
| Tab switches | Tab Bar | `6891:21297` | High | Shared |

### Navigation Rules

- **Auth required**: Yes.
- **Back behavior**: pop. Keyboard dismiss if active before pop.
- **Deep link**: `app://search` (empty) or `app://search?q=<term>`
  (pre-populates the search bar and lands in Active-query state).
- **Tab Bar**: visible.

---

## Component Schema

### Layout Structure

#### Default / empty state (parent)

```
┌─────────────────────────────────────┐
│ StatusBar                            │
├─────────────────────────────────────┤
│ [←]  [🔍 Search Sunner              ]│ ← TopNav: Back + Search bar
├─────────────────────────────────────┤
│  Recent                  [ View all ]│ ← Title row
├─────────────────────────────────────┤
│ ┌──────────────────────────────┐ [X]│ ← Recent row 1 (tap navigates,
│ │ 👤 Sunner name              │     │    X removes from history)
│ │    Department               │     │
│ └──────────────────────────────┘    │
│ ┌──────────────────────────────┐ [X]│ ← Recent row 2
│ │ 👤 Sunner name              │     │
│ └──────────────────────────────┘    │
│ … (N rows)                          │
├─────────────────────────────────────┤
│ [SAA] [Awards] [Kudos] [Profile]    │ ← Tab Bar
└─────────────────────────────────────┘
```

#### Active-query state (fold-in — `hldqjHoSRH`)

```
┌─────────────────────────────────────┐
│ StatusBar                            │
├─────────────────────────────────────┤
│ [←]  [🔍 Dương|                     ]│ ← Search bar with typed text + cursor
├─────────────────────────────────────┤
│ ┌──────────────────────────────┐    │ ← Result row 1 (no X; tap navigates)
│ │ 👤 Dương thúy An            │     │
│ │    CEVC3                    │     │
│ └──────────────────────────────┘    │
│ ┌──────────────────────────────┐    │ ← Result row 2
│ │ 👤 Dương Văn A              │     │
│ └──────────────────────────────┘    │
│ … (live-filtered)                   │
├─────────────────────────────────────┤
│ [SAA] [Awards] [Kudos] [Profile]    │
└─────────────────────────────────────┘
```

### Component Hierarchy

```
SearchSunnerScreen (SwiftUI View)
├── TopNavigation (shared)                           # 6891:21277
│   ├── BackIconButton
│   └── SearchBarField (Molecule)                    # mms_2 (empty) / mms_1.1 (typed)
│       └── InlineSearchInput (Atom)                 # "Search Sunner" placeholder
├── BackgroundImage (Atom)
│
│  — Mode: default —
├── RecentSearchesSection (Organism, visible when query == "")
│   ├── TitleRow (Molecule)                          # "Recent" + "View all" button
│   └── RecentSearchesList (Organism)
│       └── RecentRow ×N (Molecule)                  # mms_5.1 pair per row
│           ├── SunnerRowTile (Molecule)             # reused — avatar + name + dept (same `490:5562` component)
│           └── RemoveFromHistoryButton (Atom)       # close icon (`6885:14709`)
│
│  — Mode: activeQuery —
├── ActiveQuerySection (Organism, visible when query != "")
│   └── LiveResultsList (Organism)
│       └── SunnerRow ×N (Molecule)                  # same tile, NO remove button
│
└── BottomTabBar (shared)                            # 6891:21297
```

### Main Components

| Component | Type | Node ID | Description | Reusable |
|-----------|------|---------|-------------|----------|
| `TopNavigation` | Organism | `6891:21277` | App-wide nav bar — this screen hosts a `SearchBarField` in place of a title | ✅ |
| `SearchBarField` | Molecule | `6891:22074` / `6891:22135` | Embedded search input with placeholder | ✅ — candidate shared component |
| `SunnerRowTile` | Molecule | `490:5562` instances | Avatar + name + department — **same component** used by `RecipientPickerSheet` in Gửi lời chúc | ✅ **shared** |
| `RemoveFromHistoryButton` | Atom | `6885:14709` | Close / X icon button | ✅ (reusable for any removable chip/row) |
| `BottomTabBar` | Organism | `6891:21297` | Shared | ✅ |

---

## Fold-in: UI State — `ActiveQuery` (includes brief loading)

### `[iOS] Sun*Kudos_Searching` (`hldqjHoSRH`)

**Type**: UI state (active query / live results). Named "Searching" in
Figma but not a pure spinner — it shows **filled results** for a
typed query. The loading state (spinner) is transient within this
mode while the debounced API call is in-flight.

Behavior:

- Triggered when `query.trimmed.count >= 2` (hide for 0–1 chars, same
  threshold as other search fields in this app).
- **Debounce** 300 ms before hitting the API; debounce applies to every
  keystroke.
- While debouncing or awaiting the response: show a **small spinner at
  the top of the list** (`.progressView()` in the list header) so
  VoiceOver can announce "đang tìm kiếm".
- Once results arrive, the list replaces its content atomically; if
  results are empty, show the empty-state copy `"Không tìm thấy Sunner
  nào khớp \"\(query)\""`.
- `RemoveFromHistoryButton` is **not** shown in this mode (rows are
  pure tap targets).
- Selecting a result closes the keyboard, records the selection into
  Recent searches, and navigates to the Sunner's profile.

When the user clears the query (empties the search bar), the UI
transitions back to the Default / empty state and re-renders Recent.

---

## Form Fields

| Field | Type | Required | Validation |
|-------|------|----------|------------|
| Search query | `String` | no | live-filtered; min 2 chars before querying; trim whitespace; ignore input of pure whitespace / punctuation |

---

## API Mapping

Backend: **Supabase**.

### On Screen Load / Resume

| Call | Method | Purpose | Response usage |
|------|--------|---------|----------------|
| `supabase.auth.getSession()` | SDK | Auth guard | Redirect to Login if invalid |
| **Local read**: `RecentSearchesCache.load()` | local (UserDefaults + Keychain for user binding) | Populate "Recent" list | Up to N (10) entries, newest first; per-user |

### On User Action

| Action | Call | Method | Request | Response |
|--------|------|--------|---------|----------|
| Type in search bar (debounced 300 ms) | `supabase.from("profiles").select("user_id, full_name, department:departments(*), avatar_url").ilike("full_name", "%q%").limit(20)` | GET `/rest/v1/profiles` | `{ q }` | List of `SunnerRowVM` |
| Tap result row | (1) `RecentSearchesCache.add(userId)`; (2) navigate | local + nav | — | Push `[iOS] Profile người khác` (or rewrite to `/me` if self) |
| Tap Recent row body | Same — record promotion (bump to top) + navigate | — | — | — |
| Tap X on Recent row | `RecentSearchesCache.remove(userId)` | local | — | Row animates out |
| Tap "View all" | — | navigation | — | Destination TBC — v1 fallback: inline expand (no separate screen) |
| Tap Back | — | navigation | — | Pop; dismiss keyboard |
| Tab switch | — | navigation | — | Shared behaviour |

### Error Handling

| Error | Source | UI action |
|-------|--------|-----------|
| Session expired | Guard | Redirect to Login |
| Profile search failed | REST 5xx / network | Inline retry row: "Không tải được. Thử lại" |
| Query too short | Client | Hide active-query section; show default (Recent) |
| No results | REST empty | Empty-state copy (see Fold-in) |

---

## State Management

### Local State (ViewModel — Principle III)

```swift
protocol SearchSunnerViewModel {
    // Inputs
    var viewAppeared: PublishRelay<Void> { get }
    var queryChanged: PublishRelay<String> { get }        // raw input — debounce in the pipe
    var resultTapped: PublishRelay<UserID> { get }
    var removeRecentTapped: PublishRelay<UserID> { get }
    var viewAllRecentTapped: PublishRelay<Void> { get }
    var backTapped: PublishRelay<Void> { get }

    // Outputs
    var mode: Driver<SearchMode> { get }                  // .defaultRecent | .activeQuery
    var recent: Driver<[SunnerRowVM]> { get }             // top N per user
    var results: Driver<[SunnerRowVM]> { get }            // active-query results
    var isSearching: Driver<Bool> { get }                 // true while debouncing / fetching
    var emptyCopy: Driver<String?> { get }                // "Không tìm thấy…" when results empty
    var navigate: Signal<AppRoute> { get }
    var errorToast: Signal<String> { get }
}

enum SearchMode: Equatable {
    case defaultRecent
    case activeQuery(query: String)
}
```

### Pipeline sketch

```swift
let normalizedQuery = queryChanged
    .map { $0.trimmingCharacters(in: .whitespaces) }
    .distinctUntilChanged()
    .share(replay: 1)

let activeQuery = normalizedQuery
    .filter { $0.count >= 2 }
    .debounce(.milliseconds(300), scheduler: MainScheduler.instance)
    .do(onNext: { [isSearchingRelay] _ in isSearchingRelay.accept(true) })
    .flatMapLatest { q in
        repo.searchSunners(query: q)
            .asObservable()
            .catchAndReturn([])
    }
    .do(onNext: { [isSearchingRelay] _ in isSearchingRelay.accept(false) })

normalizedQuery
    .map { $0.isEmpty ? .defaultRecent : .activeQuery(query: $0) }
    .bind(to: modeRelay)
    .disposed(by: bag)
```

### Global State

| State | Store | R/W | Purpose |
|-------|-------|-----|---------|
| `AuthState` | `AuthStore` | R | Guard + self-rewrite of profile route |
| `RecentSearchesCache` | `RecentSearchesStore` (local) | R/W | Per-user history; capped at 10 |
| `UnreadNotificationCount` | `NotificationStore` | R | — *(optional — this screen doesn't show the bell in the header, but observing keeps state consistent across tabs)* |

### Recent searches — storage design

- **v1**: local only (`UserDefaults` keyed by `user_id`). Simple,
  zero server cost, respects "don't persist PII more than needed"
  because entries store only the `userId`; the row's display data is
  re-resolved from `profiles` on read.
- **v-next**: if product wants cross-device history → add a
  `user_recent_searches (user_id, target_user_id, searched_at)` table
  with RLS `USING (user_id = auth.uid())`.

---

## UI States

### Loading State

- Initial (very brief): skeleton for Recent if the profile re-resolve
  lookup is slow.
- Active-query: list-header `ProgressView` while debouncing / fetching.

### Error State

- Profile search REST error → inline retry row above the list.
- Recent resolve error (cached IDs no longer exist — user deleted) →
  silently drop the missing rows from the cache.

### Success State

- Default: Recent list populated.
- Active query: filtered result list; empty-state copy when zero
  matches.

### Empty State

- **No recent searches** (first-time user): Recent section shows
  `"Chưa có tìm kiếm gần đây. Bắt đầu gõ để tìm đồng nghiệp."` — no
  CTA needed; keyboard autofocus on first appear handles the hint.

---

## Accessibility (Principle II)

| Requirement | Implementation |
|-------------|----------------|
| Screen context | Announce `"Tìm kiếm Sunner"` on appear |
| Search bar | `.accessibilityLabel("Tìm kiếm Sunner")`; `.accessibilityHint("Nhập tên để tìm")` |
| Keyboard | Auto-focus on appear so VoiceOver users can start typing; set `.textContentType(.name)` for smart suggestions |
| Recent row | Composite: `"\(name), \(department)"` + two accessibility custom actions: `"Mở hồ sơ"` (tap) and `"Xoá khỏi lịch sử"` (the X button, exposed as a separate element with trait `.isButton`) |
| Result row | Same composite label; no remove action; trait `.isButton` |
| Searching spinner | Announce `"đang tìm kiếm"` via `.accessibilityLiveRegion(.polite)` when it becomes visible |
| Empty state | Announce the empty copy as a live region |
| Touch targets | Rows ≥ 44 pt tall; X button ≥ 44×44; Back icon wrapped in 44×44 |
| Dynamic Type | Rows reflow to 2 lines of name at AX3+ |
| Reduced motion | Disable animate-out on remove; just instant removal |
| Localisation | All copy via `Localizable.xcstrings` (VN + EN) |

---

## Responsive Behavior

| Device class | Layout |
|--------------|--------|
| iPhone portrait | As designed |
| iPhone landscape | Same; keyboard overlays ~40% |
| iPad | Max width 600 pt, centered |
| AX3+ | Row internals stack; X button moves under the row rather than trailing |

---

## Analytics Events (Optional)

| Event | Trigger | Properties |
|-------|---------|------------|
| `search_sunner.viewed` | On appear | `{ source }` — `home / sun_kudos.spotlight / profile` |
| `search_sunner.query_submitted` | Debounced query → API fired | `{ length_bucket }` — 2–3 / 4–6 / 7+ |
| `search_sunner.result_tap` | Tap result row | `{ position, was_from_recent }` |
| `search_sunner.recent_removed` | Tap X | — |
| `search_sunner.empty_result` | Query returned 0 | `{ length_bucket }` |

Never log the query string or user IDs (Principle V).

---

## Design Tokens

| Token | Usage |
|-------|-------|
| `Color("SearchBarBG")` | Search bar background |
| `Color("RowBG")` / `Color("RowSeparator")` | List row |
| `Color("TextPrimary")` / `Color("TextSecondary")` | Name / department |
| SF Symbols: `magnifyingglass`, `xmark.circle.fill` (clear query), `xmark` (remove from history) |

---

## Implementation Notes

### Clean Architecture touch-points (Principle I)

- **Presentation**:
  `Presentation/Search/Views/SearchSunnerView.swift`,
  `Presentation/Search/ViewModels/SearchSunnerViewModel.swift`,
  `Presentation/Search/ViewModels/SearchSunnerStateAdapter.swift`,
  `Presentation/Search/Components/SunnerRowTile.swift` *(extract to
  `Presentation/Shared/` — reused by `RecipientPickerSheet` and
  `SpotlightBoardView`'s accessibility fallback)*,
  `Presentation/Search/Components/SearchBarField.swift` *(shared)*.
- **Domain**:
  `Domain/UseCases/SearchSunnersUseCase.swift` — **shared with
  `RecipientPickerSheet`** from Gửi lời chúc; signature identical
  (`query: String → Single<[Profile]>`). Extract if not already.
  `Domain/UseCases/ReadRecentSearchesUseCase.swift`,
  `Domain/UseCases/AddRecentSearchUseCase.swift`,
  `Domain/UseCases/RemoveRecentSearchUseCase.swift`.
- **Data**:
  Reuse `ProfileRepositoryImpl` (already defined),
  `Data/Local/Search/RecentSearchesStorage.swift` (UserDefaults +
  `@Codable` array scoped by user id).

### Reactive model (Principle III)

- `queryChanged` uses `.distinctUntilChanged().debounce(...)` at the
  ViewModel layer — the View does not debounce.
- `flatMapLatest` cancels in-flight searches when a new query arrives.
- Recent cache updates emit an `Observable<[UserID]>` that the
  ViewModel re-maps to `SunnerRowVM` via `ProfileRepository.fetch(by:)`.

### Security (Principle V)

- `profiles` `SELECT` policy already permits authenticated users (from
  Profile specs).
- Recent-searches cache stores **only** `userId`s and timestamps —
  no names, no avatars. The tile re-renders from the live `profiles`
  row on display so it stays current (and goes away if the target user
  is deleted).
- Never log the raw query text (it could contain PII like partial
  names).

### Edge cases

- User types very fast → debounce + `flatMapLatest` ensure only the
  latest query hits the server.
- Self-match in results → do NOT exclude globally; allow the user to
  navigate to their own profile via this screen (router rewrite to
  `/me` still kicks in). Contrast with `RecipientPickerSheet` which
  DOES exclude self.
- Recent entry target user deleted → silently drop from cache; do not
  show a placeholder row.
- Deep link `app://search?q=X` → prefill and immediately enter
  Active-query mode.
- Paste into the field → same pipeline (debounce still applies).

---

## Analysis Metadata

| Property | Value |
|----------|-------|
| Analyzed By | `/momorph.screenflow` |
| Analysis Date | 2026-04-24 |
| Source | `get_overview` on `3jgwke3E8O` (depth 5) + `hldqjHoSRH` (depth 5, fold-in) |
| Fold-in type correction | User briefed fold-in as "UI State: loading results". Actual design is "active-query results" state; the **loading sub-state (spinner)** sits inside it during the debounce/fetch window. The spec documents it as a composite `ActiveQuery` state that includes the spinner phase. |
| Needs Deep Analysis | Low — only the "View all" destination is uncertain |
| Confidence Score | High for flow + data contract; Medium for "View all" destination |

### Next Steps

- [ ] Confirm the **"View all" destination** on the Recent heading.
      v1 fallback: inline expand (drop the button or make it a no-op).
- [ ] Confirm whether Recent-searches persistence should be **local
      only** (v1) or **server-synced** across devices (v-next). Decide
      during `/momorph.database`.
- [ ] Extract `SearchBarField` + `SunnerRowTile` into
      `Presentation/Shared/` during implementation — both are consumed
      by multiple screens.
- [ ] Confirm keyboard-autofocus behaviour with UX (this spec assumes
      autofocus on appear).
