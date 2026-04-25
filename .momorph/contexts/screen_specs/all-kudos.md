# Screen: [iOS] Sun*Kudos_All Kudos

## Screen Info

| Property | Value |
|----------|-------|
| **Figma Frame ID** | `j_a2GQWKDJ` (node `6891:15995`) |
| **Figma Link** | https://momorph.ai/files/9ypp4enmFmdK3YAFJLIu6C/screens/j_a2GQWKDJ |
| **Screen Group** | Sun\*Kudos cluster |
| **Platform** | iOS (SwiftUI) |
| **Status** | discovered |
| **Discovered At** | 2026-04-24 |
| **Last Updated** | 2026-04-24 |

---

## Description

`[iOS] Sun*Kudos_All Kudos` is a **full-feed list view** pushed from
the Kudos tab's "View all Kudos" button. Unlike `[iOS] Sun*Kudos`
which aggregates multiple sections (Highlight, Spotlight, stats,
preview), **this screen is a pure paginated kudo list** — no KV
banner, no filter bar, no spotlight, no stats.

Structure (from `get_overview` captured during the Sun*Kudos verify on
2026-04-24):

1. `TopNavigation` — Back icon + title **"All Kudos"**.
2. Background (shared `mm_media_bg`).
3. `header` — section header "ALL KUDOS" (shared component
   `6885:8015`).
4. `Danh sách Kudo` — vertical list of `KudoCard` instances
   (same shared component used by Profile bản thân, Sun*Kudos, View kudo).
5. `nav bar` — shared Tab Bar.

No fold-ins. No sub-sheets. No verify.

---

## Navigation Analysis

### Incoming Navigations (From)

| Source | Trigger | Condition |
|--------|---------|-----------|
| `[iOS] Sun*Kudos` | Tap "View all Kudos" button at bottom of ALL KUDOS preview section | Always |
| Deep link | `app://kudos/all` | Any time |

### Outgoing Navigations (To)

| Target | Trigger | Confidence | Notes |
|--------|---------|------------|-------|
| `[iOS] Sun*Kudos` (or caller) | TopNav Back icon | High | Standard `NavigationStack` pop |
| `[iOS] Sun*Kudos_View kudo` (`T0TR16k0vH`) | Tap any kudo card body | High | Pass `kudoId` |
| Kudo card action buttons (×2) | Buttons in card | Low | Same buttons as Profile me's KudoCard — resolve during `/momorph.specs`; likely "React / Share" for non-owner, or "Edit / Delete" for owner |
| `[iOS] Profile người khác` | Tap sender/recipient avatar or name on a card | High | Pass `userId` (reused behaviour of shared `KudoCard`) |
| Tab switches | Tab Bar | High | Shared |

### Navigation Rules

- **Auth required**: Yes.
- **Back behavior**: pop. If reached via deep link with no stack parent,
  fall through to `[iOS] Sun*Kudos`.
- **Deep link**: `app://kudos/all`.
- **Tab Bar**: visible.

---

## Component Schema

### Layout Structure

```
┌─────────────────────────────────────┐
│ StatusBar                            │
├─────────────────────────────────────┤
│ [←]    All Kudos                     │ ← TopNavigation (with title)
├─────────────────────────────────────┤
│  ALL KUDOS                           │ ← section header
├─────────────────────────────────────┤
│ ┌──────────────────────────────┐     │ ← KudoCard (shared)
│ │ [👤→👤] Trao nhận             │     │
│ │ 10:00 - 10/30/2025  IDOL…    │     │
│ │ Nội dung lời cảm ơn …         │     │
│ │ #Dedicated #Inspiring         │     │
│ │ ❤ 1,000     [btn][btn]       │     │
│ └──────────────────────────────┘     │
│ ┌──────────────────────────────┐     │
│ │ …                             │     │
│ └──────────────────────────────┘     │
│ (… N more, paginated)                │
├─────────────────────────────────────┤
│ [SAA] [Awards] [Kudos] [Profile]    │ ← Tab Bar
└─────────────────────────────────────┘
```

### Component Hierarchy

```
AllKudosScreen (SwiftUI View)
├── TopNavigation (shared)                           # 6891:16000
│   └── Title "All Kudos"
├── BackgroundImage (Atom)
├── SectionHeader (shared)                           # 6891:16644
└── KudosListView (Organism, scrollable)             # 6891:16170
    └── KudoCard ×N (shared)                         # mms_B.3_KUDO - Highlight
└── BottomTabBar (shared)                            # 6891:16694
```

### Main Components

| Component | Type | Node ID | Description | Reusable |
|-----------|------|---------|-------------|----------|
| `TopNavigation` | Organism | `6891:16000` | Shared app-wide | ✅ |
| `SectionHeader` | Molecule | `6891:16644` | Same `header` component used across the app (`6885:8015`) | ✅ |
| `KudoCard` | Organism | `6891:16171-16578` | **Same shared organism** as Profile bản thân, Sun*Kudos, Gửi lời chúc (preview) | ✅ |
| `BottomTabBar` | Organism | `6891:16694` | Shared | ✅ |

This screen is **almost entirely composed of already-introduced
components**. No new atoms/molecules are required.

---

## Form Fields (If Applicable)

Not applicable.

---

## API Mapping

Backend: **Supabase**.

### On Screen Load / Resume

| Call | Method | Purpose |
|------|--------|---------|
| `supabase.auth.getSession()` | SDK | Auth guard |
| `supabase.from("kudos").select("*, sender:profiles(*), recipient:profiles(*), hashtags(*)").eq("status", "active").order("created_at", desc: true).limit(20)` | GET `/rest/v1/kudos` | First page |
| Supabase Realtime channel `kudos:status=eq.active` | WebSocket | Prepend on INSERT |

### On User Action

| Action | Call | Method | Request | Response |
|--------|------|--------|---------|----------|
| Pull-to-refresh | Re-run first page | GET | — | Replace list |
| Scroll to bottom | `.lt("created_at", cursor).limit(20)` | GET | — | Append page |
| Tap card body | — | navigation | — | Push `[iOS] View kudo` |
| Tap heart | `supabase.rpc("toggle_heart", { kudo_id })` | POST | `{ kudo_id }` | Optimistic update |
| Tap sender/recipient avatar/name | — | navigation | — | Push `[iOS] Profile người khác` |
| Tap Back | — | navigation | — | Pop |

### Error Handling

| Error | Source | UI action |
|-------|--------|-----------|
| Session expired | Guard | Redirect to Login |
| First-page fetch failed | REST | Inline retry row at top |
| Pagination fetch failed | REST | Footer retry row |
| Heart toggle failed | REST | Revert optimistic toggle + quiet toast |
| Realtime disconnect | WS | Silent fallback to 30-s polling |

---

## State Management

### Local State (ViewModel — Principle III)

```swift
protocol AllKudosViewModel {
    // Inputs
    var viewAppeared: PublishRelay<Void> { get }
    var pullToRefresh: PublishRelay<Void> { get }
    var reachedEnd: PublishRelay<Void> { get }
    var kudoTapped: PublishRelay<KudoID> { get }
    var heartToggled: PublishRelay<KudoID> { get }
    var sunnerTapped: PublishRelay<UserID> { get }

    // Outputs
    var items: Driver<[KudoCardVM]> { get }
    var isRefreshing: Driver<Bool> { get }
    var isPaginating: Driver<Bool> { get }
    var topError: Driver<String?> { get }
    var paginationError: Driver<String?> { get }
    var navigate: Signal<AppRoute> { get }
    var errorToast: Signal<String> { get }
}
```

Mirrors the Notifications ViewModel pattern — same pagination + optimistic
update approach.

### Global State

| State | Store | R/W | Purpose |
|-------|-------|-----|---------|
| `AuthState` | `AuthStore` | R | Guard |
| `UnreadNotificationCount` | `NotificationStore` | R | — *(no bell in this screen's TopNav — the shared header is not present; the count is still observed for consistency across the session)* |

---

## UI States

### Loading State

- Initial: 5 skeleton `KudoCard` placeholders.
- Refresh: system pull-to-refresh indicator.
- Pagination: footer spinner.

### Error State

- Initial fetch → inline banner with "Thử lại" / "Retry".
- Pagination fetch → footer retry row.
- Heart fail → revert + toast.

### Success State

- List renders; Realtime prepends new cards with a short fade-in.

### Empty State

- Zero kudos in the system (unlikely in prod): empty-state copy
  `"Chưa có Kudos nào được gửi. Hãy là người đầu tiên!"` + CTA
  button `"Viết Kudos"` → pushes `[iOS] Gửi lời chúc Kudos`.

---

## Accessibility (Principle II)

| Requirement | Implementation |
|-------------|----------------|
| Screen title | `"All Kudos"` — announced by TopNavigation |
| KudoCard | Composite label reused from Profile: `"Từ \(sender) gửi \(recipient). \(award). \(body, 1 sentence). \(time)."` + action buttons as separate elements |
| Heart button | `.isButton`; label `"Tim \(n). \(isLiked ? "Đã thích" : "Chưa thích")"`; toggles trigger a short VoiceOver announcement |
| Touch targets | Card tap area fills card; heart and action buttons ≥ 44×44 |
| Dynamic Type | KudoCard reflows (shared component handles this) |
| Focus order | Back → SectionHeader → each card top-to-bottom → Tab Bar |
| Reduced motion | Disable fade-in on Realtime inserts |

---

## Responsive Behavior

| Device class | Layout |
|--------------|--------|
| iPhone portrait | Full-width cards |
| iPhone landscape | Same; list width fills viewport |
| iPad | Max width 600 pt centered |
| AX3+ | Card internals reflow (handled by shared `KudoCard`) |

---

## Analytics Events (Optional)

| Event | Trigger | Properties |
|-------|---------|------------|
| `all_kudos.viewed` | On appear | `{ source: "sun_kudos" | "deeplink" }` |
| `all_kudos.refresh` | Pull-to-refresh | — |
| `all_kudos.load_more` | Pagination | `{ page_index }` |
| `all_kudos.card_tap` | Card body tap | — |
| `all_kudos.heart_toggled` | Heart tap | `{ new_state }` |

No user_id / name / body logged (Principle V).

---

## Design Tokens

No new tokens. All visuals handled by the shared `TopNavigation`,
`SectionHeader`, `KudoCard`, and `BottomTabBar`.

---

## Implementation Notes

### Clean Architecture touch-points (Principle I)

- **Presentation**:
  `Presentation/SunKudos/Views/AllKudosView.swift`,
  `Presentation/SunKudos/ViewModels/AllKudosViewModel.swift`,
  `Presentation/SunKudos/ViewModels/AllKudosStateAdapter.swift`.
  All other components are reused from `Presentation/Shared/`.
- **Domain**:
  `Domain/UseCases/FetchAllKudosUseCase.swift` (keyset-paginated),
  `Domain/UseCases/ObserveNewKudosUseCase.swift` (Realtime INSERT stream).
- **Data**:
  Extends `KudoRepositoryImpl` with `fetchAll(cursor:)` and the
  Realtime observable — shares the same DTO + mapper used by Profile
  bản thân and Sun*Kudos.

### Reactive model (Principle III)

- **Pagination** — identical pattern to Notifications:
  ```swift
  reachedEnd
      .withLatestFrom(items) { _, current in current.last?.createdAt }
      .flatMapLatest { cursor in
          repo.fetchAll(before: cursor).asObservable()
      }
      .map(KudoCardVM.init)
      .scan(into: []) { acc, page in acc.append(contentsOf: page) }
      .bind(to: itemsRelay)
  ```
- **Realtime inserts**: `ObserveNewKudosUseCase` emits a `KudoCardVM`
  per INSERT event; prepend to `itemsRelay`. Respect RLS — the Realtime
  channel must only broadcast `status = 'active'` rows to clients.
- **Heart toggle**: same shared `ToggleHeartUseCase` used by Profile
  and Sun*Kudos.

### Security (Principle V)

- RLS on `kudos`:
  - `SELECT using (auth.uid() is not null AND (status = 'active' OR sender_id = auth.uid()))`.
    Non-authors only see active kudos; authors can still see their own
    soft-hidden / spam rows (on this screen, only active content shows
    by filter).
- Realtime must enforce the same policy server-side.
- Logs contain no kudo body, sender/recipient name, or IDs.

### Edge cases

- Realtime INSERT arrives during pagination mid-flight → insert at the
  top of the list (above the paginated anchor); do not disturb the
  keyset cursor.
- Network flaky → pagination retry row is independent from the
  top-level retry row; each block recovers independently.
- User scrolls far then pull-to-refresh → reset to first page; append
  from Realtime inserts after.
- Kudo becomes soft-hidden while visible (moderation trigger
  post-view) → remove from list via Realtime UPDATE; this spec keeps
  behaviour consistent with the backing RLS rule.

---

## Analysis Metadata

| Property | Value |
|----------|-------|
| Analyzed By | `/momorph.screenflow` |
| Analysis Date | 2026-04-24 |
| Source | `get_overview` on `j_a2GQWKDJ` (depth 5) — originally captured during the Sun*Kudos verify step |
| Needs Deep Analysis | No |
| Confidence Score | High — structurally trivial, reuses already-spec'd components |

### Next Steps

- [ ] Confirm empty-state copy + CTA destination with design.
- [ ] Confirm whether the two action buttons on each KudoCard route to
      edit/delete (owner) or react/share (non-owner) — resolve during
      `/momorph.specs` on `PV7jBVZU1N` or `T0TR16k0vH`.
- [ ] Lock `kudos` RLS policies in `/momorph.database` (includes the
      author-visibility exception for soft-hidden content).
