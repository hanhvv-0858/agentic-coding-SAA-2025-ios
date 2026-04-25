# Screen: [iOS] Sun*Kudos_View kudo

## Screen Info

| Property | Value |
|----------|-------|
| **Figma Frame ID** | `T0TR16k0vH` (node `6885:10128`) |
| **Figma Link** | https://momorph.ai/files/9ypp4enmFmdK3YAFJLIu6C/screens/T0TR16k0vH |
| **Screen Group** | Sun\*Kudos cluster |
| **Platform** | iOS (SwiftUI) |
| **Status** | discovered (with 1 fold-in variant — anonymous rendering) |
| **Discovered At** | 2026-04-24 |
| **Last Updated** | 2026-04-24 |

---

## Description

`[iOS] Sun*Kudos_View kudo` is the **kudo detail screen** — a read-only
full-page rendering of a single Kudo, reached from any list or card tap
across the app. It is the destination for Notifications N1 + N2 and
for kudo taps on Home/Sun\*Kudos/Profile/All Kudos/Search Sunner.

Layout is a larger version of the `KudoCard` molecule used in lists:

1. TopNavigation with Back + title **"Kudo"**.
2. A single content block (the kudo):
   - **Transfer header** (`trao nhận`) — sender avatar + name/dept,
     arrow, recipient avatar + name/dept.
   - Divider.
   - Posted timestamp (`10:00 - 10/30/2025`).
   - **Award title** (`NGƯỜI HÙNG CỦA LÒNG EM` in the sample — this is
     the free-text "Danh hiệu" the sender wrote in Gửi lời chúc).
   - Body paragraph.
   - Image list (up to 5 large images).
   - Hashtag row.
   - **Action row**: hearts count + heart icon + 2 action buttons.
3. Shared BottomTabBar.

The **anonymous variant** (fold-in `5C2BL6GYXL`) is an identical layout
with the sender identity masked — documented in Variants below.

---

## Navigation Analysis

### Incoming Navigations (From)

| Source | Trigger | Condition |
|--------|---------|-----------|
| `[iOS] Home` | Tap award teaser / kudos preview card | (if such cards are kudo-linked) |
| `[iOS] Notifications` N1 (Kudos received) / N2 (Kudos liked) | Row tap | Payload `kudoId` |
| `[iOS] Sun*Kudos` | Tap Highlight or preview kudo card | `kudoId` |
| `[iOS] Sun*Kudos_All Kudos` | Tap any card | `kudoId` |
| `[iOS] Sun*Kudos_Gửi lời chúc Kudos` | Post-submit success | Newly created `kudoId` |
| `[iOS] Profile bản thân` | Tap kudo in received/sent feed | `kudoId` |
| `[iOS] Profile người khác` | Tap kudo in received feed | `kudoId` |
| Deep link | `app://kudos/:kudoId` | Any time |

### Outgoing Navigations (To)

| Target | Trigger Element | Node ID | Confidence | Notes |
|--------|-----------------|---------|------------|-------|
| (previous screen) | Back Icon | `6885:10137` | High | Standard pop |
| `[iOS] Profile người khác` (sender) | Tap sender avatar / name | `6885:10150` | High *(when not anonymous)* | Disabled in anonymous variant |
| `[iOS] Profile bản thân` (sender) | Tap own sender | — | High | Router self-rewrite |
| `[iOS] Profile người khác` (recipient) | Tap recipient avatar / name | `6885:10153` | High | Always tappable |
| `[iOS] Profile bản thân` (recipient) | Tap own recipient | — | High | Router self-rewrite |
| Full-screen image viewer | Tap any image in `mms_B.4_Nội dung.list` | `6885:10168` | Medium | System `QuickLook` (or a custom `ImageViewer` sheet). Design doesn't show a viewer frame; implementation gap to resolve during `/momorph.specs` |
| (stay) Heart toggle | Tap heart icon | `6885:10179` | High | Optimistic toggle via shared `ToggleHeartUseCase` RPC |
| (stay) Action buttons — 2 ×buttons | `Buttons` row | `6885:10181` + `6885:10186` | Low | Purpose not labelled in overview. Candidates: **Share** + **Report** (for non-owner) OR **Edit** + **Delete** (for owner). Resolve during `/momorph.specs` — this spec encodes both roles behind a capability check (see Domain model). |
| Tab switches | Tab Bar | `6891:16715` | High | Shared |

### Navigation Rules

- **Auth required**: Yes.
- **Back behavior**: pop. Fall through to `[iOS] Sun*Kudos` if reached
  via deep link with no parent.
- **Deep link**: `app://kudos/:kudoId`.
- **Tab Bar**: visible.
- **Anonymous sender tap**: NOT navigable — the sender surface is
  rendered as plain text (no avatar link, no `accessibilityTraits
  .isButton`) in the anonymous variant.

---

## Component Schema

### Layout Structure

```
┌─────────────────────────────────────┐
│ StatusBar                            │
├─────────────────────────────────────┤
│ [←]    Kudo                          │ ← TopNavigation
├─────────────────────────────────────┤
│ ┌─────────────────────────────────┐ │ ← mms_B.3 card (large detail variant)
│ │ [👤 Sender]   →   [👤 Recipient]│ │ ← trao nhận (transfer header)
│ │  Tên, phòng ban      Tên, phòng │ │
│ │ ─────────────                   │ │
│ │ 10:00 - 10/30/2025              │ │
│ │ NGƯỜI HÙNG CỦA LÒNG EM          │ │ ← award title (sender-authored)
│ │                                 │ │
│ │ Nội dung lời cảm ơn dài…       │ │
│ │                                 │ │
│ │ [img][img][img][img][+1]        │ │ ← images (up to 5, large)
│ │ #Dedicated #Inspiring #…        │ │ ← hashtags
│ │                                 │ │
│ │ ❤ 10         [btn1][btn2]      │ │ ← actions
│ └─────────────────────────────────┘ │
├─────────────────────────────────────┤
│ [SAA] [Awards] [Kudos] [Profile]    │ ← Tab Bar
└─────────────────────────────────────┘
```

### Component Hierarchy

```
ViewKudoScreen (SwiftUI View) — ViewModel injects `kudoId`
├── TopNavigation (shared)                           # 6885:10133
│   └── Title "Kudo"
├── BackgroundImage (Atom)
├── KudoDetailView (Organism)                        # mms_B.3_KUDO (detail variant)
│   ├── TransferHeader (Molecule)                    # trao nhận
│   │   ├── SenderInfor (Molecule)                   # reuses Infor component `6885:8347`
│   │   │   ├── SenderAvatarBlock (Molecule)         # mm_media_img — childCount 2 (standard) / 3 (anonymous)
│   │   │   └── SenderIdentityBlock (Molecule)       # name + department
│   │   ├── ArrowIcon (Atom)                         # mms_B.3.4_Icon mũi tên
│   │   └── RecipientInfor (Molecule)                # same Infor component
│   ├── Divider                                      # Rectangle 15
│   ├── PostedAt (Atom)                              # mms_B.4.1
│   ├── AwardTitle (Atom)                            # free text from sender — e.g. "NGƯỜI HÙNG CỦA LÒNG EM"
│   ├── BodyBlock (Molecule)                         # mms_B.4
│   │   ├── BodyText (Atom)                          # mms_B.4.2_Nội dung
│   │   ├── ImageGallery (Molecule)                  # 5 slots of Image component `6885:8812`
│   │   └── HashtagsRow (Atom)                       # mms_B.4.3
│   ├── ActionRow (Molecule)                         # mms_B.4.4_Action
│   │   ├── HeartCounter + HeartIcon (Molecule)
│   │   └── ActionButtons (Molecule, ×2)             # capability-driven (see below)
│   └── Divider                                      # Rectangle 14 (parent only)
└── BottomTabBar (shared)                            # 6891:16715
```

### Main Components

| Component | Type | Node ID | Description | Reusable |
|-----------|------|---------|-------------|----------|
| `TopNavigation` | Organism | `6885:10133` | App-wide | ✅ |
| `KudoDetailView` | Organism | `6885:10148` | **Distinct** from `KudoCard` — larger image size, larger typography, no truncation | **Yes — the detail variant** of the same content type; share rendering of `TransferHeader`/`BodyBlock`/`ActionRow` atoms with `KudoCard` |
| `TransferHeader` | Molecule | `6885:10149` | Sender → recipient block; same structure as `KudoCard`'s | ✅ |
| `ImageGallery` | Molecule | `6885:10168` | Larger thumbs than the card; tappable to a full-screen viewer | ✅ |
| `ActionButtons` (×2) | Molecule | `6885:10180` | **Capability-driven** — wires up different actions for owner vs. viewer (see Domain model + "Next Steps") | ✅ |
| `BottomTabBar` | Organism | `6891:16715` | Shared | ✅ |

---

## Variants (fold-in)

### AnonymousRendering — `[iOS] Sun*Kudos_View kudo ẩn danh` (`5C2BL6GYXL`)

**Type**: conditional rendering variant. ≥ 95% layout similarity with
parent; only the sender surface differs.

#### Visual diff vs parent

- **Sender `Infor` → `mm_media_img`**: childCount **3** in anonymous vs
  **2** in parent. The extra child is an **anonymity mask/overlay**
  (a rendered "mask" or "?" badge on top of the avatar slot).
- **Sender display name**: replaced with `kudo.anonymous_nickname`
  (what the sender typed in `Gửi lời chúc` when anonymous=on). The
  accompanying department line is hidden.
- **Sender avatar**: replaced with a neutral anonymous placeholder
  (no real avatar).
- **Sender tap area**: **disabled** — the sender block is not a
  navigation target; no tap gesture, no accessibility button trait.
- **Recipient side**: unchanged (always real and tappable).
- Everything else — divider, timestamp, award title, body, images,
  hashtags, hearts, action buttons — **identical** to the parent.

#### Implementation switch

```swift
struct KudoDetailView: View {
    let kudo: KudoDetailVM

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if kudo.isAnonymous {
                TransferHeader(sender: .anonymous(nickname: kudo.anonymousNickname),
                               recipient: .real(kudo.recipient))
            } else {
                TransferHeader(sender: .real(kudo.sender),
                               recipient: .real(kudo.recipient))
            }
            // … (rest is identical)
        }
    }
}
```

A single `TransferHeader` molecule accepts two `Party` cases —
`.real(Profile)` and `.anonymous(nickname: String)` — and renders
accordingly. The Figma "`mm_media_img` childCount 3" simply adds the
mask overlay inside the anonymous rendering of the avatar.

#### Security & identity leakage (Principle V)

This is the **load-bearing** security rule for anonymous kudos:

- When `kudo.is_anonymous = true`, the server MUST NOT return
  `sender_id`, `sender_full_name`, `sender_avatar_url`, or
  `sender_department` in the row shape for non-privileged viewers.
  - **Exception**: the author themselves sees their own sender
    identity (they remember what they sent).
  - **Exception**: admins may be allowed to see it for moderation
    (out of scope for iOS v1).
- The RLS-equivalent redaction is implemented as a **view**
  (`kudos_view`) that CASEs on `is_anonymous` + `auth.uid()`:

  ```sql
  CREATE VIEW kudos_view AS
  SELECT
      id, recipient_id, created_at, award_title, body, hashtag_ids,
      attachment_urls, hearts_count, status, is_anonymous,
      -- sender fields are NULLED when anonymous and viewer ≠ author ≠ admin
      CASE
          WHEN is_anonymous AND auth.uid() <> sender_id AND NOT is_admin(auth.uid())
          THEN NULL ELSE sender_id
      END AS sender_id,
      CASE
          WHEN is_anonymous AND auth.uid() <> sender_id AND NOT is_admin(auth.uid())
          THEN anonymous_nickname
          ELSE NULL
      END AS displayed_sender_name,
      -- …
  FROM kudos;
  ```

- The iOS client MUST NOT attempt to look up `sender_id` via
  `@mention` parsing or image EXIF. Treat absence of sender fields as
  the authoritative anonymity signal.
- Do NOT log the kudo body, the anonymous nickname, or the real
  sender's id (even when visible).

---

## Form Fields (If Applicable)

Not applicable — this is a read-only detail screen.

---

## API Mapping

Backend: **Supabase**.

### On Screen Load / Resume

| Call | Method | Purpose | Response usage |
|------|--------|---------|----------------|
| `supabase.auth.getSession()` | SDK | Auth guard | Redirect to Login |
| `supabase.from("kudos_view").select("*").eq("id", kudoId).single()` | GET `/rest/v1/kudos_view` | Fetch the kudo with identity-redaction applied by the view | Populate `KudoDetailVM` |
| Supabase Realtime on `kudos:id=eq.:kudoId` (UPDATE) | WebSocket | Live hearts counter + moderation status changes | Update UI if hearts/status changes while screen is open |

### On User Action

| Action | Call | Method | Request | Response |
|--------|------|--------|---------|----------|
| Tap Back | — | navigation | — | Pop |
| Tap sender (real only) | — | navigation | — | Push Profile người khác (or self-rewrite) |
| Tap recipient | — | navigation | — | Push Profile người khác (or self-rewrite) |
| Tap heart | `supabase.rpc("toggle_heart", { kudo_id })` | POST | `{ kudo_id }` | `{ hearts, is_liked }` — optimistic update |
| Tap image | — | local | — | Present full-screen `ImageViewer` (system QuickLook or custom) |
| Tap Action Button 1 (TBC: Share / Edit) | navigation OR SKAction | — | — | See capability matrix below |
| Tap Action Button 2 (TBC: Report / Delete) | navigation OR REST | — | — | See capability matrix below |

### Action button capabilities (by viewer role)

| Viewer role | Button 1 | Button 2 |
|-------------|----------|----------|
| **Owner (author)** | Edit → opens Gửi lời chúc prefilled with draft (TBC: is edit even allowed post-publish?) | Delete → `DELETE /rest/v1/kudos?id=eq.kudoId` + confirmation dialog |
| **Viewer (non-owner)** | Share → `UIActivityViewController` with deep link `app://kudos/:id` | Report → opens a report sheet → writes `kudo_reports(kudo_id, reporter_id, reason)` |
| **Recipient (subset of viewer)** | Same as Viewer | Same as Viewer |

This matrix is my best inference. The exact button semantics **must be
confirmed during `/momorph.specs`**. This spec documents both roles
behind a `KudoAction` enum so the Domain layer abstracts the lookup.

### Error Handling

| Error | Source | UI action |
|-------|--------|-----------|
| Session expired | Guard | Redirect to Login |
| Kudo not found (404 / empty) | REST | Navigate to `[iOS] Not Found` with `source: .notification` or `.deeplink` |
| Kudo soft-hidden (viewer not author) | RLS filter returns empty | Same — treat as not found |
| Kudo deleted mid-view (Realtime DELETE) | WS | Show inline banner "Kudo đã bị xoá" then pop after 2 s |
| Heart toggle failed | REST | Revert optimistic; quiet toast |
| Image load failed | Storage | Show a placeholder thumb with retry tap |
| Delete failed (owner action) | REST | Toast; stay on screen |
| Report submit failed | REST | Toast; stay on report sheet |

---

## State Management

### Local State (ViewModel — Principle III)

```swift
protocol ViewKudoViewModel {
    init(kudoId: KudoID)

    // Inputs
    var viewAppeared: PublishRelay<Void> { get }
    var senderTapped: PublishRelay<Void> { get }       // ignored when anonymous
    var recipientTapped: PublishRelay<Void> { get }
    var imageTapped: PublishRelay<Int> { get }          // index 0..4
    var heartToggled: PublishRelay<Void> { get }
    var action1Tapped: PublishRelay<Void> { get }       // dispatched by capability
    var action2Tapped: PublishRelay<Void> { get }

    // Outputs
    var kudo: Driver<KudoDetailVM?> { get }
    var isLoading: Driver<Bool> { get }
    var actionButton1: Driver<KudoActionVM?> { get }    // label + icon, driven by role
    var actionButton2: Driver<KudoActionVM?> { get }
    var navigate: Signal<AppRoute> { get }
    var presentImageViewer: Signal<Int> { get }         // starting index
    var presentReportSheet: Signal<Void> { get }
    var presentDeleteConfirm: Signal<Void> { get }
    var presentShareSheet: Signal<URL> { get }          // the kudo deep link
    var toast: Signal<ToastVM> { get }
}
```

### Domain model

```swift
struct KudoDetailVM {
    let id: KudoID
    let sender: Party                       // .real(Profile) | .anonymous(nickname)
    let recipient: Profile
    let postedAt: Date
    let awardTitle: String                  // sender-authored
    let body: AttributedString
    let imageURLs: [URL]                    // ≤ 5
    let hashtags: [Hashtag]
    let hearts: Int
    let isLiked: Bool
    let status: KudoStatus                  // .active | .softHidden | .spam
    let isAnonymous: Bool
    let capabilities: KudoCapabilities      // { canEdit, canDelete, canReport, canShare }
}

enum Party: Equatable {
    case real(Profile)
    case anonymous(nickname: String)
}

struct KudoCapabilities: Equatable {
    let canEdit: Bool
    let canDelete: Bool
    let canReport: Bool
    let canShare: Bool

    // Simple derivation from role
    static func from(viewer: UserID, sender: UserID?, isAdmin: Bool) -> Self {
        let isOwner = (sender == viewer)
        return .init(
            canEdit: isOwner,                   // TBC with product
            canDelete: isOwner || isAdmin,
            canReport: !isOwner,
            canShare: true
        )
    }
}
```

### Global State

| State | Store | R/W | Purpose |
|-------|-------|-----|---------|
| `AuthState` | `AuthStore` | R | Guard + capability computation |
| `CurrentUser` | `AuthStore` | R | viewer for capability comparison |

---

## UI States

### Loading State

- Initial: skeleton card (transfer header + 3 skeleton text lines +
  1 skeleton image row).
- Heart toggle: instant optimistic; no loader.
- Image load: per-thumb skeleton.

### Error State

- Kudo not found → navigate away to Not Found.
- Realtime DELETE → transient banner + auto-pop.
- Heart fail → quiet toast.
- Delete fail / Report fail → toast.

### Success State

- All content rendered; hearts count live; Realtime updates in-place.

### Empty State

- N/A (detail view of a concrete kudo).

### Soft-hidden-visible-to-owner state

- If viewer = author and `status = .softHidden` → overlay a soft banner
  at the top: `"Lời nhắn này đang bị tạm ẩn do vi phạm tiêu chuẩn cộng
  đồng. Xem chi tiết."` with a link to `[iOS] Tiêu chuẩn cộng đồng`.
  Other viewers should not reach this state (RLS returns empty).

---

## Accessibility (Principle II)

| Requirement | Implementation |
|-------------|----------------|
| Screen context | `"Chi tiết Kudo"` on appear |
| Transfer header | Composite label: `"Gửi từ \(senderLabel) tới \(recipientName), phòng \(recipientDept)"`. For anonymous: `"Gửi ẩn danh từ \(nickname) tới \(recipientName)"` |
| Anonymous sender | NOT a button (no `.isButton`); presented as static text so VoiceOver users understand it's not navigable |
| Award title | `.accessibilityAddTraits(.isHeader)` |
| Body | Read naturally with `lineLimit(nil)` |
| Hashtags | Each chip is a separate element; traits depend on whether tapping them filters elsewhere (v1: non-interactive — verify with design) |
| Heart | Trait `.isButton`; state announcement `"Tim. \(n). \(isLiked ? "Đã thích" : "Chưa thích")"` |
| Action buttons | Dynamic label from capability matrix; traits `.isButton`; hint per action |
| Image | Trait `.isButton`; label `"Ảnh \(n) / \(total). Nhấn để xem phóng to."` |
| Touch targets | All ≥ 44×44 |
| Dynamic Type | Detail card reflows at AX3+; images remain fixed aspect |
| Reduced motion | No animations |
| Localisation | VN + EN keys for all labels |

---

## Responsive Behavior

| Device class | Layout |
|--------------|--------|
| iPhone portrait | As designed; image thumbs 2×2 + 1 |
| iPhone landscape | Content scrolls; images wider |
| iPad | Max width 600 pt centered |
| AX3+ | Transfer header stacks vertically; images become full-width |

---

## Analytics Events (Optional)

| Event | Trigger | Properties |
|-------|---------|------------|
| `view_kudo.viewed` | On appear | `{ source, is_anonymous, is_owner, is_recipient }` |
| `view_kudo.sender_tap` | Sender tap (non-anonymous) | — |
| `view_kudo.recipient_tap` | Recipient tap | — |
| `view_kudo.image_tap` | Image tap | `{ index, total }` |
| `view_kudo.heart_toggled` | Heart tap | `{ new_state }` |
| `view_kudo.share_tap` | Share action | — |
| `view_kudo.report_tap` | Report action | — |
| `view_kudo.edit_tap` (if allowed) | Edit action | — |
| `view_kudo.delete_confirmed` | Delete confirm | — |

Never log body, nickname, names/ids, award title (Principle V).

---

## Design Tokens

| Token | Usage |
|-------|-------|
| `Color("TextPrimary")` | Body, award title |
| `Color("TextSecondary")` | Timestamp, department |
| `Color("HeartActive")` | Liked heart |
| `Color("AnonymousMask")` | Mask overlay on anonymous avatar |
| `Color("SoftHiddenBanner")` | Banner when viewing own soft-hidden content |
| Font: `.title3` → award title, `.body` → body, `.footnote` → timestamp, `.callout` → hashtags |
| SF Symbols: `heart` / `heart.fill`, `square.and.arrow.up` (share), `flag` (report), `pencil` (edit), `trash` (delete), `eye.slash` (anonymous mask) |

---

## Implementation Notes

### Clean Architecture touch-points (Principle I)

- **Presentation**:
  `Presentation/SunKudos/Views/ViewKudoView.swift`,
  `Presentation/SunKudos/ViewModels/ViewKudoViewModel.swift`,
  `Presentation/SunKudos/ViewModels/ViewKudoStateAdapter.swift`,
  `Presentation/SunKudos/Components/KudoDetailView.swift`,
  `Presentation/Shared/Components/TransferHeaderView.swift` *(shared
  with `KudoCard`)*,
  `Presentation/Shared/Components/ImageGalleryView.swift`,
  `Presentation/Shared/Components/ImageViewer.swift` (full-screen).
- **Domain**:
  `Domain/UseCases/FetchKudoByIdUseCase.swift` (returns
  `KudoDetailVM` with redacted sender),
  `Domain/UseCases/ObserveKudoUseCase.swift` (Realtime UPDATE stream
  for hearts + status),
  `Domain/UseCases/DeleteKudoUseCase.swift`,
  `Domain/UseCases/ReportKudoUseCase.swift`,
  `Domain/UseCases/ShareKudoUseCase.swift` (returns deep link),
  `Domain/Entities/KudoDetail.swift`, `Party.swift`, `KudoCapabilities.swift`.
- **Data**:
  Extends `KudoRepositoryImpl` with `fetchById`, `delete`, `report`,
  plus the `observe` channel.

### Reactive model (Principle III)

- Initial fetch + Realtime stream `combine` into a single
  `Observable<KudoDetailVM>`:
  ```swift
  let kudoStream = Observable.concat(
      repo.fetchById(kudoId).asObservable(),
      repo.observe(kudoId)           // never completes
  )
  .share(replay: 1)
  ```
- Heart toggle is optimistic + reconciles on Realtime update.
- Navigation emits a single merged `Signal<AppRoute>`.
- Capabilities computed once post-fetch in a pure mapping function.

### Security (Principle V)

- `kudos_view` (or equivalent) **redacts sender fields server-side**
  when `is_anonymous = true` and viewer is not author/admin. Client
  never receives identifying fields in that case.
- RLS on base `kudos`:
  - `SELECT using (auth.uid() is not null AND (status = 'active' OR sender_id = auth.uid()))`.
- `DELETE using (sender_id = auth.uid() OR is_admin(auth.uid()))`.
- `kudo_reports` table: INSERT allowed for any authenticated user;
  `reporter_id = auth.uid()` via `with check`.
- Storage: image URLs from `kudo_attachments` bucket; policies remain
  as set by Gửi lời chúc (owner can insert; read per product policy).
- **Never** log body, nickname, name, user_id, award title.

### Edge cases

- Deep link to a kudo the viewer can't see → Not Found.
- Kudo transitions `active → soft_hidden` while open (Realtime
  UPDATE) and viewer is not author → pop to previous screen with a
  toast.
- Anonymous kudo where viewer IS the author → show real sender
  identity (that's themselves); also show a small "Chỉ mình bạn
  thấy tên thật" hint so the author knows others won't see it.
- Action button semantics: view the Owner matrix only if viewer
  `== sender` AND not anonymous-hiding-from-owner (never happens
  since owner sees themselves).
- Share deep link: copy to clipboard + system share sheet; the
  receiver's app must handle `app://kudos/:id` → resolve via
  `/momorph.specs` / deep-link infra tasks.
- Sharing a soft-hidden kudo → block share for non-authors (never
  visible anyway). For authors: allow? TBC.
- Image count = 0 → hide `ImageGallery` section entirely.

---

## Analysis Metadata

| Property | Value |
|----------|-------|
| Analyzed By | `/momorph.screenflow` |
| Analysis Date | 2026-04-24 |
| Source | `get_overview` on `T0TR16k0vH` (depth 5) + `5C2BL6GYXL` (depth 5, fold-in variant) |
| Fold-in confirmed | ✅ Anonymous variant = same layout with sender `mm_media_img` childCount +1 (mask overlay) + display name swapped for `anonymous_nickname` + tap disabled. ≥ 95% layout similarity. |
| Needs Deep Analysis | The 2 action buttons — exact semantics (Share/Report vs Edit/Delete) to confirm during `/momorph.specs`. Full-screen image viewer design not in scope (pattern-only). |
| Confidence Score | High for structure + data contract + anonymity model; Medium for action-button semantics |

### Next Steps

- [ ] **Confirm the 2 action buttons** with design — probable matrix:
      owner → Edit / Delete; non-owner → Share / Report. Lock into
      `KudoCapabilities`.
- [ ] Decide whether editing is allowed post-publish (v1 default: **no
      edit**, delete only — with "soft-hidden" as the moderation
      pathway). This simplifies the matrix to: owner → Delete only
      + Share; non-owner → Share / Report.
- [ ] Decide full-screen image viewer: system `QuickLook` vs custom
      `ImageViewer`. Design does not show a frame — pick a pattern
      consistent with the rest of the app.
- [ ] Confirm deep link scheme for share: `app://kudos/:id` (and/or
      a web URL like `kudos.saa.sun-asterisk.com/:id` for cross-app
      sharing).
- [ ] Lock `kudos_view` + RLS + `kudo_reports` table in
      `/momorph.database`.
- [ ] Extract `TransferHeaderView` shared component during implementation
      (consumed by both `KudoCard` and `KudoDetailView`).
