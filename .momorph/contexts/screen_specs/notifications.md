# Screen: [iOS] Notifications

## Screen Info

| Property | Value |
|----------|-------|
| **Figma Frame ID** | `_b68CBWKl5` (node `6885:9370`) |
| **Figma Link** | https://momorph.ai/files/9ypp4enmFmdK3YAFJLIu6C/screens/_b68CBWKl5 |
| **Screen Group** | Core App |
| **Platform** | iOS (SwiftUI) |
| **Status** | discovered |
| **Discovered At** | 2026-04-24 |
| **Last Updated** | 2026-04-24 |

---

## Description

`[iOS] Notifications` is the **user's notification inbox**, pushed onto the
stack when the user taps the 🔔 bell in the Home header (the same bell
whose dot indicator reflects unread count). Each row represents a typed
notification — Kudos received, Kudos liked, Secret Box granted, level-up,
content soft-hide, badge/prize, or admin-review request — with a contextual
icon, copy, relative timestamp, an optional unread dot, and for some
types an embedded action button.

Design samples from the Figma frame reveal **7 distinct notification
types** (`N1`–`N7`) — the list in production will be longer and
paginated.

Top bar exposes a "Đánh dấu đọc tất cả" ("Mark all as read") shortcut.

---

## Navigation Analysis

### Incoming Navigations (From)

| Source | Trigger | Condition |
|--------|---------|-----------|
| `[iOS] Home` | Tap bell icon in header | Any time (badge dot irrelevant — user can open when empty) |
| Future: APNs push → tapping a system banner | OS-level navigation | Routes to the inbox (or directly to the target, see below) |

### Outgoing Navigations (To)

Per-type mapping of what each notification row navigates to **when the
row body is tapped**:

| Type | Sample copy | Target | Confidence | Notes |
|------|-------------|--------|------------|-------|
| **N1 — Kudos received** | "Sunner … vừa gửi đến bạn lời ghi nhận đầy yêu thương!" | `[iOS] Sun*Kudos_View kudo` with `kudoId` | High | Primary use case; unread dot is typically present on the newest ones |
| **N2 — Kudos liked** | "Wow! Lời nhắn gửi của bạn cho Sunner … vừa nhận thêm lượt tim!" | `[iOS] Sun*Kudos_View kudo` with `kudoId` | High | Same destination; screen shows like count |
| **N3 — Secret Box granted** | "Chúc mừng! Bạn vừa nhận được lượt mở Secret Box mới! Click vào đây để mở ngay nhé!" | `[iOS] Open secret box` (`kQk65hSYF2`) | High | — |
| **N4 — Level up** | "Bạn nhận được <X> lời nhắn gửi … và thăng hạng <tên level>!" | `[iOS] Profile bản thân` (`hSH7L8doXB`) anchored to level section | Medium | Confirm anchor during Profile analysis |
| **N5 — Content soft-hidden** | "Tiếc quá! Bạn có một lời nhắn bị tạm ẩn…" | `[iOS] Sun*Kudos_Tiêu chuẩn cộng đồng` (`xms7csmDhD`) | High | Row carries its own **"tiêu chuẩn cộng đồng"** action button — see below |
| **N6 — Badge / prize** | "Chúc mừng bạn đã thu thập đủ 6 huy hiệu của SAA…" | `[iOS] Profile bản thân` anchored to badges section | Medium | Or a dedicated rewards screen, TBC during Profile analysis |
| **N7 — Admin review request** | "Có \<x\> lời nhắn cần bạn xem xét!" | **Admin review screen** — currently **no `[iOS]` frame in scope** | Low | The web admin has `Admin - Review content` (`MTExSUSdUn`); iOS equivalent is missing. Treat as v-next: v1 may route to `[iOS] Not Found`, OR hide the row on iOS |

### Embedded action buttons inside rows

| Row type | Button | Target |
|----------|--------|--------|
| **N5 — Content soft-hidden** | "Xem tiêu chuẩn cộng đồng" (shortcut) | `[iOS] Sun*Kudos_Tiêu chuẩn cộng đồng` |

Only **N5** has an inline action button in the sampled rows. Other rows
rely on whole-row tap.

### Top bar / non-row actions

| Action | Target | Notes |
|--------|--------|-------|
| Back icon | Previous screen (Home in 99% of cases) | Standard `NavigationStack` pop |
| "Đánh dấu đọc tất cả" | Local action (PATCH) — no navigation | Sets `read_at = now()` on all unread rows for the user; clears Home bell dot |
| Pull-to-refresh | Refresh list | — |
| Scroll to bottom | Fetch next page | Paginated |

### Navigation Rules

- **Auth required**: **Yes**. Redirect to Login if session invalid on appear.
- **Tab Bar**: remain visible (user can switch tabs to escape).
- **Back behavior**: pop to whatever pushed (Home most of the time).
- **Deep link**: `app://notifications` lands here.
- **Tapping a row**: marks that single row as read (side effect) **before**
  navigating to the target. Unread dot disappears immediately; server
  update is fire-and-forget with offline retry.

---

## Component Schema

### Layout Structure

```
┌─────────────────────────────────────┐
│ StatusBar                            │
├─────────────────────────────────────┤
│ [←]  Notifications                   │ ← TopNavigation (with title)
├─────────────────────────────────────┤
│                        [✓ Đánh dấu   │ ← mms_Button_read all
│                         đọc tất cả]  │
├─────────────────────────────────────┤
│ ┌─────────────────────────────────┐ │ ← Notification list (scrollable)
│ │ [icon] Kudos text            • │ │  N1 unread (dot)
│ │        15 phút trước            │ │
│ ├─────────────────────────────────┤ │
│ │ [icon] Like text                │ │  N2 read
│ │        1 giờ trước              │ │
│ ├─────────────────────────────────┤ │
│ │ [icon] Secret Box text          │ │  N3
│ │        1 ngày trước             │ │
│ ├─────────────────────────────────┤ │
│ │ [icon] Level-up text            │ │  N4
│ ├─────────────────────────────────┤ │
│ │ [icon] Soft-hide text           │ │  N5 (has inline button)
│ │ [Xem tiêu chuẩn cộng đồng]      │ │
│ │        1 tháng trước            │ │
│ ├─────────────────────────────────┤ │
│ │ [icon] Badge text               │ │  N6
│ ├─────────────────────────────────┤ │
│ │ [icon] Admin review text        │ │  N7 (admin-only)
│ └─────────────────────────────────┘ │
│          … more rows (paginated)     │
├─────────────────────────────────────┤
│ [SAA] [Awards] [Kudos] [Profile]    │ ← Tab Bar (shared)
└─────────────────────────────────────┘
```

### Component Hierarchy

```
NotificationsScreen (SwiftUI View)
├── TopNavigation (shared)                         # 6885:9374
│   └── Title "Notifications"                      # 6885:9380
├── BackgroundImage (Atom)                         # bg
├── MarkAllReadButton (Molecule)                   # mms_Button_read all (6885:9392)
│   ├── CheckIcon (Atom)
│   └── Label "Đánh dấu đọc tất cả"
├── NotificationListView (Organism, scrollable)    # 6885:9393
│   └── NotificationRow ×N (Molecule)              # typed variants
│       ├── NotificationIcon (Atom)                # icon varies by type
│       ├── NotificationContent (Molecule)
│       │   ├── BodyText (Atom, multi-line)
│       │   ├── InlineActionButton (Atom — N5 only)
│       │   └── RelativeTimestamp (Atom)
│       └── UnreadDot (Atom — only when !read)
└── BottomTabBar (shared, unchanged)
```

### NotificationRow variants

`NotificationRow` is **typed**. Each `NotificationType` provides:

- `iconAsset`: `Image("notif_ic_\(type)")` or an SF Symbol.
- `formattedBody(payload)`: string builder (supports parameter
  interpolation — Sunner name, level name, X count, …).
- `actionButton: InlineActionButton?`: only N5.
- `tapTarget(payload)`: `AppRoute` value for navigation on row tap.

```swift
enum NotificationType: String, Codable {
    case kudosReceived          // → .sunKudos(.viewKudo(id: payload.kudoId))
    case kudosLiked             // → .sunKudos(.viewKudo(id: payload.kudoId))
    case secretBoxGranted       // → .secretBox
    case levelUp                // → .profile(.me).anchor(.level)
    case contentSoftHidden      // → .sunKudos(.communityStandards)
    case badgeCollected         // → .profile(.me).anchor(.badges)
    case adminReviewRequest     // → .adminReview (not in iOS v1)
}
```

### Main Components

| Component | Type | Node ID | Description | Reusable |
|-----------|------|---------|-------------|----------|
| `TopNavigation` | Organism | `6885:9374` | Same shared organism as Access denied / Not Found | Yes — shared |
| `MarkAllReadButton` | Molecule | `6885:9392` | Shortcut text-button with leading check icon | No (Notifications-only) |
| `NotificationRow` | Molecule | `6885:9394-9400` | Typed row with icon + content + optional unread dot + optional inline CTA | Yes (same row type can be reused in future feeds) |
| `UnreadDot` | Atom | `I6885:9394;128:2915` | Same visual vocabulary as the Home bell dot | Yes — shared |

---

## Form Fields (If Applicable)

Not applicable — no user input on this screen.

---

## API Mapping

Backend: **Supabase**. Table: `notifications` with RLS scoped to
`recipient_id = auth.uid()`. Pagination via keyset (`created_at` +
`id`). Realtime channel for push-style updates.

### On Screen Load / Resume

| Call | Method | Purpose | Response |
|------|--------|---------|----------|
| `supabase.auth.getSession()` | SDK local | Auth guard | Redirect to Login if invalid |
| `supabase.from("notifications").select("*").eq("recipient_id", uid).order("created_at", desc: true).limit(20)` | GET `/rest/v1/notifications` | First page | Populate list |
| Supabase Realtime channel `notifications:recipient_id=eq.uid` | WebSocket | Listen for new rows + updates | Prepend to list; update `UnreadCount` store |

### On User Action

| Action | Call | Method | Request | Response |
|--------|------|--------|---------|----------|
| Pull-to-refresh | Re-run first page query | — | — | Replace list with latest |
| Scroll to bottom | `.lt("created_at", oldestCreatedAt).limit(20)` | GET | — | Append next page |
| Tap row (any) | (1) Optimistic UI: mark row as read locally. (2) `supabase.from("notifications").update({read_at: now()}).eq("id", rowId)`. (3) Navigate to `tapTarget`. | PATCH | `{ read_at }` | Row returns `read_at`; errors are retried in background |
| Tap inline "tiêu chuẩn cộng đồng" (N5) | Same as tap row but navigation = `.sunKudos(.communityStandards)` regardless of row body tap | PATCH | — | — |
| Tap "Đánh dấu đọc tất cả" | `supabase.from("notifications").update({read_at: now()}).eq("recipient_id", uid).is("read_at", nil)` | PATCH | — | All rows → `read_at = now()`; Home bell dot clears |

### Error Handling

| Error | Source | UI action |
|-------|--------|-----------|
| Session expired | `getSession()` returns nil | Redirect to Login |
| First-page fetch failed | REST 5xx / network | Inline error row at top of list with "Thử lại" / "Retry"; keep any cached rows visible |
| Pagination fetch failed | REST 5xx / network | Stop loader; show footer error row with retry |
| Mark-read PATCH failed | REST error | Keep optimistic local state; enqueue retry; surface subtle non-blocking toast only if retry exhausted |
| Realtime disconnect | WS error | Silent fallback to 30-second polling |
| Admin-only row missing route (N7 in iOS v1) | Local | Route to `[iOS] Not Found` with `source: .internalNav` OR hide the row (decision below) |

---

## State Management

### Local State (ViewModel — Principle III)

```swift
protocol NotificationsViewModel {
    // Inputs
    var viewAppeared: PublishRelay<Void> { get }
    var pullToRefresh: PublishRelay<Void> { get }
    var reachedEnd: PublishRelay<Void> { get }
    var rowTapped: PublishRelay<NotificationID> { get }
    var inlineActionTapped: PublishRelay<NotificationID> { get }
    var markAllReadTapped: PublishRelay<Void> { get }

    // Outputs
    var items: Driver<[NotificationRowVM]> { get }
    var isRefreshing: Driver<Bool> { get }
    var isLoadingMore: Driver<Bool> { get }
    var topError: Driver<String?> { get }
    var paginationError: Driver<String?> { get }
    var navigate: Signal<AppRoute> { get }
    var errorToast: Signal<String> { get }
}
```

| State | Type | Initial | Purpose |
|-------|------|---------|---------|
| `items` | `[NotificationRowVM]` | `[]` | Page-ordered rows |
| `isRefreshing` | `Bool` | `false` | Pull-to-refresh indicator |
| `isLoadingMore` | `Bool` | `false` | Footer spinner for pagination |
| `topError` | `String?` | `nil` | Shown as inline retry row when first page fails |
| `paginationError` | `String?` | `nil` | Shown as footer retry row when next page fails |

### Global State

| State | Store | R/W | Purpose |
|-------|-------|-----|---------|
| `AuthState` | `AuthStore` | R | Auth guard |
| `UnreadNotificationCount` | `NotificationStore` | R/W | Shared with Home bell dot; decremented on per-row read; zeroed on mark-all-read |

---

## UI States

### Loading State

- **Initial**: 5 skeleton rows.
- **Refresh**: system pull-to-refresh `ProgressView`; old rows stay visible.
- **Pagination**: small footer spinner beneath the last row.

### Error State

- **Initial fetch error**: inline banner at top of list:
  `"Không tải được. Thử lại"` / `"Couldn't load. Retry"`.
- **Pagination error**: footer row with the same retry affordance.
- **Per-row PATCH error**: silent retry × 3; only if all fail, surface a
  toast `"Không đánh dấu được. Đã lưu để thử lại sau."`
- **Realtime disconnect**: silent fallback to polling; no UI change.

### Success State

- List renders; unread dot visible on rows with `read_at == nil`.
- When list transitions from having unread rows → zero unread rows (after
  mark-all-read), play a very short fade on the unread dots to visually
  confirm.

### Empty State

- If the user has **zero** notifications: show an empty-state card inside
  the list area with a friendly illustration and copy:
  `"Chưa có thông báo mới"` / `"No notifications yet"`. Do NOT use the
  shared `ErrorStateView` here — empty is not an error.

---

## Accessibility (Principle II)

| Requirement | Implementation |
|-------------|----------------|
| Screen title | Reads `"Notifications"` on appear via `TopNavigation` title announcement |
| Row label | Composite: `"\(notification body). \(relativeTimestamp).\(isUnread ? " Chưa đọc." : "")"` |
| Row trait | `.isButton`; `accessibilityHint` per type, e.g. N1 → `"Mở lời ghi nhận từ Sunner này"` |
| Inline button (N5) | Separate `.isButton` element with label `"Xem tiêu chuẩn cộng đồng"` |
| Mark-all-read | `accessibilityLabel("Đánh dấu tất cả thông báo là đã đọc")` |
| Unread dot | Announced via the row's composite label, not as a separate element (avoid noise) |
| Touch targets | Rows ≥ 60 pt tall; mark-all-read button ≥ 44 pt |
| Dynamic Type | Row bodies use `.body` + `lineLimit(nil)`; rows grow vertically at AX3+ |
| Focus order | Back → Mark-all-read → rows top-down |
| Reduced motion | No row entry animations; skeletons static |

---

## Responsive Behavior

| Device class | Layout |
|--------------|--------|
| iPhone portrait | Full-width rows as designed |
| iPhone landscape | Same; list fills width |
| iPad | Max width 600 pt, centered; list density unchanged |

---

## Analytics Events (Optional)

| Event | Trigger | Properties |
|-------|---------|------------|
| `notifications.viewed` | On appear | `{ unread_count_bucket }` |
| `notifications.refresh` | Pull-to-refresh | — |
| `notifications.load_more` | Pagination | `{ page_index }` |
| `notifications.row_tap` | Row tap | `{ type, was_unread }` |
| `notifications.inline_action_tap` | N5 inline button | `{ type: "contentSoftHidden" }` |
| `notifications.mark_all_read` | Mark-all-read | `{ unread_before }` |

Never log the notification text or any named person — only types and
counts (Principle V).

---

## Design Tokens

| Token | Usage |
|-------|-------|
| `Color("DotBadge")` | Unread dot — same token as Home bell |
| `Color("TextPrimary")` | Row body |
| `Color("TextSecondary")` | Timestamp |
| `Color("RowSeparator")` | 1 pt dividers between rows |
| Font: `.body` → row body, `.footnote` → timestamp, `.headline` → mark-all-read label |
| SF Symbols (fallback if custom icons unavailable): `heart.fill` (N2), `gift.fill` (N3), `rosette` (N4), `exclamationmark.triangle.fill` (N5), `medal.fill` (N6), `flag.fill` (N7) |
| Custom assets: `notif_ic_kudos_received` (N1), …one per type |

Assets identified per sample: 7 distinct icon instances — confirm the
full set with design during `/momorph.specs`.

---

## Implementation Notes

### Clean Architecture touch-points (Principle I)

- **Presentation**:
  `Presentation/Notifications/Views/NotificationsView.swift`,
  `Presentation/Notifications/ViewModels/NotificationsViewModel.swift`,
  `Presentation/Notifications/ViewModels/NotificationsStateAdapter.swift`,
  `Presentation/Notifications/Components/NotificationRowView.swift`,
  `Presentation/Notifications/Components/MarkAllReadButton.swift`.
- **Domain**:
  `Domain/UseCases/FetchNotificationsUseCase.swift` (keyset paginated),
  `Domain/UseCases/MarkNotificationReadUseCase.swift`,
  `Domain/UseCases/MarkAllNotificationsReadUseCase.swift`,
  `Domain/UseCases/ObserveNotificationsUseCase.swift` (Realtime stream,
  reused by Home for the bell count),
  `Domain/Entities/Notification.swift` (value + typed payload),
  `Domain/Repositories/NotificationRepository.swift`.
- **Data**:
  `Data/Repositories/NotificationRepositoryImpl.swift`,
  `Data/Remote/Notifications/NotificationRemoteDataSource.swift`,
  `Data/Remote/Notifications/NotificationDTO.swift`.

### Reactive model (Principle III)

- **Pagination**:

  ```swift
  reachedEnd
      .withLatestFrom(items) { _, current in current.last?.createdAt }
      .flatMapLatest { cursor in repo.fetchNext(before: cursor).asObservable() }
      .map(NotificationRowVM.init)
      .scan(into: []) { acc, page in acc.append(contentsOf: page) }
      .bind(to: itemsRelay)
  ```

- **Per-row read**:

  ```swift
  rowTapped
      .do(onNext: { [relay] id in optimisticallyMarkRead(id) })
      .flatMap { id in repo.markRead(id).catchAndReturn(()) }
      .subscribe()
      .disposed(by: bag)
  ```

- **Realtime**: Same `ObserveNotificationsUseCase` used by Home; its
  output is the source of truth for `UnreadNotificationCount` and for
  prepending new rows on this screen while visible.

### Security (Principle V)

- **RLS required** on `notifications`:
  - `SELECT using (recipient_id = auth.uid())`.
  - `UPDATE using (recipient_id = auth.uid()) with check (recipient_id = auth.uid())`.
- Realtime subscription must replicate the same policy — do NOT broadcast
  cross-user notifications to the client channel.
- The row body text may contain a Sunner's name. That's intentional for
  display, but logs / analytics MUST NOT capture the body or the Sunner
  name — type + count only.
- If server-side denormalised the body text, make sure it never contains
  anything the recipient isn't already authorised to see (e.g. redact
  anonymous-sender identity).

### Edge cases

- **Admin review row (N7) on iOS v1**: decide with product —
  - Option A (recommended for v1): server filters `adminReviewRequest`
    out for non-admin recipients. Non-admin iOS users never receive
    them; no client-side gating needed.
  - Option B: client renders the row but taps route to
    `[iOS] Not Found` with `source: .internalNav` (friendly dead-end).
  - Option C: the row carries `role_required: "admin"`; the client hides
    rows whose `role_required` fails the current user's role.
- **Kudo deleted after notification was issued**: tapping N1/N2 fetches
  the kudo; if it returns empty → navigate to `[iOS] Not Found` with
  `source: .notification`.
- **Secret Box already opened**: tapping N3 routes to the Open-secret-box
  screen; its UI state handles "already opened".
- **Timestamp rendering**: "15 phút trước" / "1 giờ trước" / "1 ngày
  trước" / "1 tháng trước" must use `RelativeDateTimeFormatter` with the
  current locale; never hard-code Vietnamese literals in code.

---

## Analysis Metadata

| Property | Value |
|----------|-------|
| Analyzed By | `/momorph.screenflow` |
| Analysis Date | 2026-04-24 |
| Source | `get_overview` on `_b68CBWKl5` (depth 5) |
| Needs Deep Analysis | No (row taxonomy is derivable from sample copy) |
| Confidence Score | High for N1/N2/N3/N5; Medium for N4/N6 (exact deep-link anchor within Profile); Low for N7 (no iOS admin screen yet in scope) |

### Next Steps

- [ ] Confirm with product: admin-review row (N7) handling — recommend
      server-side filtering (Option A above).
- [ ] Confirm Profile anchors (`.level`, `.badges`) during Profile
      analysis (next run: `hSH7L8doXB`).
- [ ] Add `notifications` table + RLS + indexes (`recipient_id`,
      `created_at desc`) in `/momorph.database`.
- [ ] Add `notification_type` enum + typed payloads to the OpenAPI / DB
      schema during `/momorph.apispecs`.
- [ ] Run `/momorph.specs 9ypp4enmFmdK3YAFJLIu6C _b68CBWKl5` for icon
      tokens + exact typography sizes.
