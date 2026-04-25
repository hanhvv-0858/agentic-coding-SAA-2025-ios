# Screen: [iOS] Open secret box

## Screen Info

| Property | Value |
|----------|-------|
| **Figma Frame ID** | `kQk65hSYF2` (node `6885:9402`) — primary `closed` state |
| **Figma Link** | https://momorph.ai/files/9ypp4enmFmdK3YAFJLIu6C/screens/kQk65hSYF2 |
| **Screen Group** | Sun\*Kudos cluster (Secret Box mechanic) |
| **Platform** | iOS (SwiftUI) |
| **Status** | discovered (with 2 fold-in UI states + 1 animation cluster of 7 keyframes) |
| **Discovered At** | 2026-04-24 |
| **Last Updated** | 2026-04-24 |

---

## Description

`[iOS] Open secret box` is the **gift-reveal screen** at the end of the
Sun\*Kudos mechanic. Per Thể lệ:

> "Cứ mỗi 5 lượt ❤️, bạn sẽ được mở 1 Secret Box, với cơ hội nhận về
> một trong 6 icon độc quyền của SAA."

And per Notification N6 (badge/prize):

> "Chúc mừng bạn đã thu thập đủ 6 huy hiệu của SAA. Bạn đã nhận được
> phần quà từ BTC chính là \<X\>."

This screen is the single surface that handles all three logical
states of a Secret Box session:

| State | Trigger | Visual |
|-------|---------|--------|
| **Closed** (parent) | Screen appear with ≥ 1 unopened grant | "KHÁM PHÁ SECRET BOX CỦA BẠN" + "Click vào box để mở" + closed-gift image + "Secret box chưa mở: 05" |
| **Tapping** (fold-in `KUmv414uC9`) | User taps the box | Header text unchanged; closed-gift asset swaps to **opening-gift** asset (`mm_media_mở quà`); server call initiated |
| **Revealed** (fold-in `-LIblaeusT` + 6 animation keyframes) | Server returns the prize | Header becomes **"Chúc mừng bạn đã nhận được phần quà từ BTC SAA 2025"**; gift asset replaced by `mm_media_Quà` (`lot chuot` — animated reveal); prize name rendered below — sample `"Khăn Root Further"` |

All 8 total frames (1 parent + action-tapped + 7 Standby keyframes)
represent the **same logical screen** with different animation phases.

### Animation-keyframe cluster

The 7 Standby frames (`-LIblaeusT` primary + 6 siblings) are
keyframes of the reveal animation transitioning from `tapping` to
`revealed`. This spec folds them into this document — **do not create
separate `screen_specs/*.md` files**. The implementation drives all
keyframes programmatically via SwiftUI `.transition()` / `TimelineView`
or Lottie, with the primary asset (`-LIblaeusT`) as the terminal
frame.

Keyframe frame IDs (for the asset-export pass during `/momorph.specs`):
`-LIblaeusT` *(primary)*, `IXpGakYRm5`, `_cWAEarZPi`, `scvV-OQCAJ`,
`wsI6gaO_yc`, `FvTOS7oCPU`, `xptNUunBS_`.

### Prize taxonomy

The reveal surfaces a single prize each time. Based on Thể lệ + the
sample revealing `"Khăn Root Further"`, prizes can be either:

- **Digital badge** — one of the 6-icon set (REVIVAL / TOUCH OF LIGHT
  / STAY GOLD / FLOW TO HORIZON / BEYOND THE BOUNDARY / ROOT FUTHER).
- **Physical prize** — e.g. `"Khăn Root Further"` (likely delivered
  offline by BTC).

```swift
enum SecretBoxPrize: Equatable {
    case badge(BadgeKind)                        // one of 6
    case physical(name: String, assetKey: String) // e.g. "Khăn Root Further"
}
```

The **server decides** the prize at open time (authoritative, not
random-client). Confirm the exact prize pool rules in
`/momorph.database`.

### Design anomaly (ignore in implementation)

Both the parent frame `kQk65hSYF2` and the `action bấm mở` fold-in
`KUmv414uC9` contain an **orphan "Notification list" block** — 6
notification rows copy-pasted from the Notifications screen. This is
a **designer leftover** (not part of the intended Secret Box UI).
The implementation MUST NOT render this block. Verified by direct
comparison of the frame tree — the notification rows are identical to
those on `[iOS] Notifications`, including the same contentIds and
text, which is non-semantic for this screen.

---

## Navigation Analysis

### Incoming Navigations (From)

| Source | Trigger | Condition |
|--------|---------|-----------|
| `[iOS] Profile bản thân` | Tap "Mở Secret Box" button in StatsDashboard | unopened count > 0 (primary entry) |
| `[iOS] Notifications` N3 (`secretBoxGranted`) | Tap row | Any time |
| Deep link | `app://secret-box` | Any time |

### Outgoing Navigations (To)

| Target | Trigger Element | Node ID | Confidence | Notes |
|--------|-----------------|---------|------------|-------|
| (previous screen) | Back Icon | `6885:9421` | High | Standard pop |
| **State**: Tapping | Tap box image | `6885:9441` (`mms_Box image`) | High | In-screen state change + server call |
| **State**: Revealed | Server returns prize | — | High | Auto-advance from Tapping (~400 ms animation) |
| (stays) Reveal done | Animation complete | — | High | User sees the prize + count decrements to `04` |
| (stays) Open next | Tap "Open next box" CTA (TBC with design — not in overview) OR tap box again | — | Low | If unopened count remains > 0, allow another open. Current design does not show a dedicated button — tapping the box (now reset to closed asset with new count) is inferred. Confirm during `/momorph.specs`. |
| `[iOS] Profile bản thân` → `.badges` anchor (if prize is a badge) | Auto-action after N sec or "Xem huy hiệu" CTA | — | Low | Suggested UX — not in current design |
| Tab switches | No Tab Bar present on this screen | — | — | **This screen has NO Tab Bar** (unlike most authenticated screens). Confirmed by overview — no `nav bar` node. |

### Navigation Rules

- **Auth required**: Yes.
- **Back behavior**: pop. If the user navigates away mid-reveal, the
  server-side open is **already committed** (the prize is theirs).
  Subsequent visit shows the granted prize in their Profile.
- **Deep link**: `app://secret-box`.
- **No Tab Bar**: intentional — Secret Box is a focused modal-like
  flow. Confirm with design that this is intentional (not a design
  miss).

---

## Component Schema

### Layout Structure

#### Closed state (parent)

```
┌─────────────────────────────────────┐
│ StatusBar                            │
├─────────────────────────────────────┤
│ [←]    Secret Box                    │ ← TopNavigation
├─────────────────────────────────────┤
│                                      │
│     KHÁM PHÁ SECRET BOX CỦA BẠN     │ ← Header title
│     ──────────                       │
│     Click vào box để mở              │ ← Subtitle
│                                      │
│                                      │
│         [🎁 closed box]              │ ← mms_Box image (tappable)
│                                      │
│          ──────────                  │ ← divider
│                                      │
│        Secret box chưa mở            │
│             05                       │ ← count
└─────────────────────────────────────┘
```

#### Tapping state (fold-in `KUmv414uC9`)

Same as closed; only the box asset changes:

```
│         [📦 opening box]             │ ← mm_media_mở quà
```

#### Revealed state (fold-in `-LIblaeusT` + keyframes)

```
┌─────────────────────────────────────┐
│ StatusBar                            │
├─────────────────────────────────────┤
│ [←]    Secret Box                    │
├─────────────────────────────────────┤
│                                      │
│   Chúc mừng bạn đã nhận được         │ ← new header
│   phần quà từ BTC SAA 2025           │
│     ──────────                       │
│                                      │
│                                      │
│     [✨ prize reveal ✨]             │ ← mms_C_Box image
│     (waiting + gift animation)       │
│                                      │
│          ──────────                  │
│                                      │
│         Khăn Root Further            │ ← mms_D_Title (prize name)
│                                      │
└─────────────────────────────────────┘
```

### Component Hierarchy

```
OpenSecretBoxScreen (SwiftUI View) — finite state machine
├── TopNavigation (shared)                           # 6885:9406
│   └── Title "Secret Box"
├── BackgroundImage (Atom)                           # bg
└── SecretBoxStage (Organism)                        # renders current state
    │
    ├─ case .closed:
    │   ├── HeaderBlock (Molecule)                   # "KHÁM PHÁ SECRET BOX CỦA BẠN" + "Click vào box để mở"
    │   ├── BoxImageButton (Atom)                    # closed box asset; tap → .tapping
    │   ├── Divider
    │   └── UnopenedCounter (Molecule)               # "Secret box chưa mở: 05"
    │
    ├─ case .tapping:
    │   ├── HeaderBlock (unchanged)
    │   ├── BoxImageButton (Atom)                    # opening box asset; disabled
    │   ├── Divider
    │   └── UnopenedCounter (unchanged)
    │
    └─ case .revealed(prize):
        ├── HeaderBlock (Molecule)                   # "Chúc mừng …"
        ├── PrizeRevealAnimation (Organism)          # 7-keyframe Lottie/SwiftUI sequence
        │   ├── WaitingBackdrop (Atom)               # "Trạng thái chờ" rect
        │   └── PrizeAsset (Atom)                    # mm_media_Quà + "lot chuot" animation
        ├── Divider
        └── PrizeTitle (Atom)                        # e.g. "Khăn Root Further"
```

### Main Components

| Component | Type | Node ID | Description | Reusable |
|-----------|------|---------|-------------|----------|
| `TopNavigation` | Organism | `6885:9406` | Shared app-wide | ✅ |
| `HeaderBlock` | Molecule | `6885:9435` / `6885:9786` | Title + divider + subtitle | ✅ (reused across Error States, Thể lệ, Community Standards) |
| `BoxImageButton` | Atom | `6885:9441` / `6885:9571` | Tappable box asset — 2 variants (closed / opening) | No (screen-specific) |
| `UnopenedCounter` | Molecule | `6885:9445` | Label + big number | Yes (stats-like pattern) |
| `PrizeRevealAnimation` | Organism | `6885:9790` | Keyframe-driven reveal | No (screen-specific) |
| `PrizeTitle` | Atom | `6885:9794` | Dynamic prize name | Yes (generic label) |

---

## UI States (fold-in)

### Tapping — `[iOS] Open secret box- action bấm mở` (`KUmv414uC9`)

**Type**: UI state after user taps the box.

- Triggered: user taps `BoxImageButton` while `.closed` state is
  active.
- Visual diff: swap closed-gift asset → opening-gift asset
  (`mm_media_mở quà`). Rest of layout unchanged.
- Behavior:
  - Play a short anticipation animation (~200 ms).
  - Fire `openSecretBox()` RPC in parallel.
  - Block further taps on the box.
  - On server response, advance to `.revealed(prize)`.
  - On error, revert to `.closed` with a toast.

### Revealed (+ Animation) — `[iOS] Open secret box- trạng thái Standby`

**Type**: UI state `revealed` + animation cluster.

- Triggered: server response received with the prize.
- Visual: header copy changes to congratulation; box asset replaced
  with reveal sequence; prize name rendered below divider.
- Animation cluster (7 keyframes):
  - Primary: `-LIblaeusT` (terminal frame).
  - Additional keyframes: `IXpGakYRm5`, `_cWAEarZPi`, `scvV-OQCAJ`,
    `wsI6gaO_yc`, `FvTOS7oCPU`, `xptNUunBS_`.
- Implementation: play keyframes sequentially (200 ms each, total
  ~1.4 s) using SwiftUI `TimelineView` or a Lottie asset. **Respect
  `UIAccessibility.isReduceMotionEnabled`** — for reduce-motion
  users, skip straight to the terminal frame with a 150 ms crossfade.
- Side effects:
  - Decrement `unopened count` locally (`Profile` stats re-fetch on
    next appear).
  - If prize is a `.badge`, mark it as newly-collected in
    `CurrentUser.badgesOwned`.
  - If this opening completes the 6-badge set, trigger the mystery
    prize flow on the server (that's server-side; the client just
    shows whatever prize the server returns in the current reveal).

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
| `supabase.from("secret_box_grants").select("*", count:"exact", head:true).eq("user_id", uid).is("opened_at", nil)` | HEAD | Count of unopened boxes |

If count = 0 on appear → show a friendly empty state (see below) and
do NOT allow tapping to open.

### On User Action

| Action | Call | Method | Request | Response |
|--------|------|--------|---------|----------|
| Tap box | `supabase.rpc("open_secret_box", {})` | POST `/rest/v1/rpc/open_secret_box` | `{}` — server picks the next unopened grant for this user | `{ prize_type: 'badge' \| 'physical', prize_name, prize_asset_key, badge_kind? }` — server-assigned |
| Tap Back | — | navigation | — | Pop |
| (after reveal) Tap box again if count > 0 | Same as first tap | — | — | — |

### Error Handling

| Error | Source | UI action |
|-------|--------|-----------|
| Session expired | Guard | Redirect to Login |
| Count fetch failed | REST | Show retry banner; keep box hidden until resolved |
| Zero boxes left (concurrent opening in another session) | RPC returns `{ error: "no_boxes_left" }` | Revert to `.closed`; toast "Bạn đã mở hết Secret Box. Gửi thêm Kudos để nhận box mới." |
| Server error during open | RPC 5xx | Revert to `.closed`; toast with retry |
| Prize asset load failed | Storage | Show a placeholder; don't block the reveal (the prize is already committed server-side) |

---

## State Management

### Local State (ViewModel — Principle III)

```swift
protocol OpenSecretBoxViewModel {
    // Inputs
    var viewAppeared: PublishRelay<Void> { get }
    var boxTapped: PublishRelay<Void> { get }
    var backTapped: PublishRelay<Void> { get }

    // Outputs
    var stage: Driver<SecretBoxStage> { get }      // .closed | .tapping | .revealed(prize)
    var unopenedCount: Driver<Int> { get }
    var isInteractionDisabled: Driver<Bool> { get }
    var errorToast: Signal<String> { get }
    var navigate: Signal<AppRoute> { get }
}

enum SecretBoxStage: Equatable {
    case closed
    case tapping
    case revealed(SecretBoxPrize)
}
```

### State machine

```
                    appear / count > 0
                          │
                          ▼
                      [ .closed ]
                          │
                 tap (count > 0)
                          │
                          ▼
                     [ .tapping ]
                 ┌────┴────┐
                 │         │
         rpc success    rpc failure
                 │         │
                 ▼         ▼
       [ .revealed(prize) ]   [ .closed ] + toast

     tap (count > 0 after reveal) → back to .tapping
```

### Global State

| State | Store | R/W | Purpose |
|-------|-------|-----|---------|
| `AuthState` | `AuthStore` | R | Guard |
| `CurrentUser.badgesOwned` | `AuthStore` (or its projection) | Optimistic W on badge reveal | Update UI across other screens on return |
| `ProfileStats` | re-fetched on next Profile appear | — | The unopened counter on Profile recalculates |

---

## UI States (master)

### Loading State

- Count fetch: lightweight — just don't show the box until it resolves
  (usually < 100 ms).
- Reveal fetch: the `.tapping` state IS the loading state; no
  additional spinner.

### Error State

- See Error Handling table.
- A toast banner appears above TopNavigation content (auto-dismiss
  ~3 s).

### Success State

- `.revealed(prize)` renders the prize + title.

### Empty State — zero unopened

- Empty-state copy: `"Bạn chưa có Secret Box nào để mở. Gửi thêm
  Kudos và nhận đủ tim để mở hộp mới!"`
- CTA: `"Viết Kudos"` → pushes `[iOS] Sun*Kudos_Gửi lời chúc Kudos`.

---

## Accessibility (Principle II)

| Requirement | Implementation |
|-------------|----------------|
| Screen context | `"Secret Box"` on appear |
| Box button | `.isButton`; label `"Mở Secret Box"`; hint `"Nhấn để mở một hộp quà"`. When disabled during `.tapping`, trait `.isButton` with `.accessibilityTraits(.notEnabled)` |
| Unopened counter | `"Secret box chưa mở: \(n)"` |
| Reveal header | `"Chúc mừng bạn đã nhận được phần quà từ BTC SAA 2025"` — `.accessibilityAddTraits(.isHeader)` |
| Prize title | Announced via `.accessibilityLiveRegion(.polite)` when `.revealed` first appears |
| Animation | Respect `UIAccessibility.isReduceMotionEnabled` — skip to terminal frame |
| Touch target | Box button fills a ≥ 200×200 pt tap area (visible size) |
| Dynamic Type | Header + prize title scale to AX5 |
| Focus order | Back → Header → Box (or Prize) → Counter (or Prize title) |

---

## Responsive Behavior

| Device class | Layout |
|--------------|--------|
| iPhone portrait | As designed |
| iPhone landscape | Box centred; content scrolls if needed |
| iPad | Max width 480 pt, centered |
| AX3+ | Header + subtitle wrap naturally; box size fixed |

---

## Analytics Events (Optional)

| Event | Trigger | Properties |
|-------|---------|------------|
| `secret_box.viewed` | On appear | `{ unopened_count_bucket, source }` |
| `secret_box.tap` | User taps the box | `{ remaining_before_tap }` |
| `secret_box.revealed` | `.revealed` state | `{ prize_type, badge_kind? }` — **NEVER** log the physical prize name beyond a coarse type |
| `secret_box.failed` | Open RPC error | `{ code }` |
| `secret_box.empty_view` | Appear with count = 0 | — |
| `secret_box.back` | Back tap | `{ from_stage }` |

Principle V: log prize TYPE, not specific physical-prize names (which
could be PII-adjacent if tied to delivery info).

---

## Design Tokens

| Token | Usage |
|-------|-------|
| `Color("SecretBoxBG")` | Dedicated brand backdrop for this screen |
| `Color("PrizeGlow")` | Glow around reveal animation |
| Font: `.title2` → header, `.largeTitle` → count / prize, `.body` → subtitle |
| Assets: `Image("box_closed")`, `Image("box_opening")`, `Image("prize_\(assetKey)")` (per-prize) |

Keyframe assets exported from the 7 Standby frames — one Lottie file
preferred (`secret_box_reveal.json`) over 7 separate PNG sequences.

---

## Implementation Notes

### Clean Architecture touch-points (Principle I)

- **Presentation**:
  `Presentation/SecretBox/Views/OpenSecretBoxView.swift`,
  `Presentation/SecretBox/ViewModels/OpenSecretBoxViewModel.swift`,
  `Presentation/SecretBox/ViewModels/OpenSecretBoxStateAdapter.swift`,
  `Presentation/SecretBox/Components/BoxImageButton.swift`,
  `Presentation/SecretBox/Components/PrizeRevealAnimation.swift`
  *(Lottie-based preferred)*.
- **Domain**:
  `Domain/UseCases/FetchUnopenedBoxCountUseCase.swift`,
  `Domain/UseCases/OpenSecretBoxUseCase.swift`,
  `Domain/Entities/SecretBoxPrize.swift` (enum),
  `Domain/Entities/SecretBoxStage.swift` (finite state).
- **Data**:
  `Data/Repositories/SecretBoxRepositoryImpl.swift`,
  `Data/Remote/SecretBox/SecretBoxRemoteDataSource.swift`,
  `Data/Remote/SecretBox/OpenSecretBoxResponseDTO.swift`.

### Reactive model (Principle III)

- ViewModel is a **finite state machine** driven by a
  `BehaviorRelay<SecretBoxStage>`.
- `boxTapped` is gated:
  ```swift
  boxTapped
      .withLatestFrom(stageRelay)
      .filter { $0 == .closed }
      .do(onNext: { [stageRelay] _ in stageRelay.accept(.tapping) })
      .flatMapLatest { _ in
          repo.openBox()
              .asObservable()
              .materialize()
      }
      .subscribe(onNext: { event in
          switch event {
          case .next(let prize): stageRelay.accept(.revealed(prize))
          case .error(let err): stageRelay.accept(.closed)
                                errorRelay.accept(err.localizedDescription)
          default: break
          }
      })
      .disposed(by: bag)
  ```

### Security (Principle V)

- **Server is authoritative** for prize assignment. The `open_secret_box`
  RPC:
  - Checks `auth.uid()` has ≥ 1 unopened grant with
    `policy using (user_id = auth.uid())`.
  - Atomically picks a grant (lock-then-update), assigns a prize via
    the configured pool, marks `opened_at = now()`, returns the prize.
  - Must be idempotent in the face of client retries (safe to call
    twice; the second call either returns the same result if the
    previous one is still uncommitted, or hits "no boxes left" if it
    already succeeded).
- **Client MUST NOT** attempt to pre-compute prizes, influence
  randomness, or bypass the RPC. Ticking an unopened grant with a raw
  `UPDATE` from the client MUST be forbidden by RLS.
- RLS on `secret_box_grants`:
  - `SELECT using (user_id = auth.uid())`.
  - `UPDATE` — no direct UPDATE from client; only through the RPC.
- Logs contain only the prize TYPE (`"badge"` / `"physical"`) and, at
  most, the `badge_kind` enum value. Never log physical prize names,
  delivery info, or recipient address (if that ever lives in the
  system).

### Prize pool & mystery prize

- Prize pool configuration (weights, remaining stock of physical
  prizes) is server-side config. Resolve during `/momorph.database`.
- The "collected all 6 badges → mystery prize" path (per Thể lệ +
  Notification N6) is server-triggered: when a `secret_box_grants`
  opening causes the user's `badges_owned` set to reach 6, the server
  either:
  - returns `.physical(...)` on that same RPC (preferred simple path), OR
  - inserts a separate `secret_box_grants` row tagged as
    `{ pool: 'mystery' }` and notifies the user via N6.
- This spec assumes the first model (simpler client; fewer states).

### Edge cases

- **No boxes left mid-tap** (concurrent session): recover to `.closed`
  + toast.
- **User navigates away mid-reveal**: server side is already committed;
  prize is theirs; visible on next Profile appear.
- **Reduce motion**: skip to terminal keyframe.
- **Low-end device**: if Lottie is too heavy, fall back to a single
  PNG + 300 ms crossfade; feature flag `secretBoxLottie.enabled`.
- **Orphan "Notification list" in the design**: do NOT render. Flag
  for designers to clean up the Figma frame.
- **Physical prize asset missing**: render the prize name + a generic
  gift icon.

---

## Analysis Metadata

| Property | Value |
|----------|-------|
| Analyzed By | `/momorph.screenflow` |
| Analysis Date | 2026-04-24 |
| Source | `get_overview` on 3 frames: `kQk65hSYF2` (parent, depth 5) + `KUmv414uC9` (tapping, depth 5) + `-LIblaeusT` (Standby primary, depth 4). The other 6 keyframes (`IXpGakYRm5`, `_cWAEarZPi`, `scvV-OQCAJ`, `wsI6gaO_yc`, `FvTOS7oCPU`, `xptNUunBS_`) are mentioned without deep inspection — they share the same layout as `-LIblaeusT` and differ only in animation-phase visuals. |
| Design anomaly flagged | Both `kQk65hSYF2` and `KUmv414uC9` contain an **orphan 6-row "Notification list" block** copy-pasted from the Notifications screen. Ignore in implementation; flagged for design cleanup. |
| Needs Deep Analysis | Low — structure clear; prize pool rules TBC in database spec |
| Confidence Score | High for structure + state machine; Medium for exact animation timings and prize pool rules |

### Next Steps

- [ ] Confirm **"Open next box" UX** when `unopened_count > 0` after
      a reveal: dedicated CTA vs. tapping the resetted box again.
      Design does not show a CTA — this spec assumes re-tap.
- [ ] Confirm **absence of Tab Bar** is intentional on this screen
      (this spec follows the design).
- [ ] Decide **single RPC with prize type** vs. **separate mystery-
      prize path** for the "6 badges collected" case during
      `/momorph.database`. This spec recommends single RPC.
- [ ] Clean up the **orphan Notification list** in Figma frames
      `kQk65hSYF2` + `KUmv414uC9`.
- [ ] Export **keyframe asset(s)** during `/momorph.specs`:
      prefer a single Lottie file (`secret_box_reveal.json`) plus a
      PNG fallback for low-end devices.
- [ ] Add `secret_box_grants` table + RLS + `open_secret_box` RPC
      (SECURITY DEFINER, atomic lock-then-update) in
      `/momorph.database`.
- [ ] Confirm the sample prize `"Khăn Root Further"` is a real
      physical prize and gather its asset key.
