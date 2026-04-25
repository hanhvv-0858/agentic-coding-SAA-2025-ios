# Screen: [iOS] Sun*Kudos_Gửi lời chúc Kudos (Compose a Kudo)

## Screen Info

| Property | Value |
|----------|-------|
| **Figma Frame ID** | `PV7jBVZU1N` (node `6885:9883`) |
| **Figma Link** | https://momorph.ai/files/9ypp4enmFmdK3YAFJLIu6C/screens/PV7jBVZU1N |
| **Screen Group** | Sun\*Kudos cluster |
| **Platform** | iOS (SwiftUI) |
| **Status** | discovered (with 2 fold-in sub-sheets + 2 fold-in UI states) |
| **Discovered At** | 2026-04-24 |
| **Last Updated** | 2026-04-24 |

---

## Description

`[iOS] Sun*Kudos_Gửi lời chúc Kudos` is the **compose screen** for writing
a new Kudo — the write-side complement of `[iOS] Sun*Kudos_View kudo`.
TopNavigation title: **"New Kudo"**.

The form has six inputs plus a toggle:

1. **Người nhận** — recipient (required, picked via search sub-sheet).
2. **Danh hiệu** — award title (required, free text, ≤ ~80 chars;
   displayed as the Kudo's title on the card).
3. **Nội dung** — Kudo body (required, rich-text area with a 7-button
   formatting toolbar, supports `@mention` to tag other Sunners).
4. **Hashtag** — at least one required (multi-select from sub-sheet +
   ability to add ad-hoc tags).
5. **Image** — optional, up to **5** attachments.
6. **Gửi ẩn danh** — optional checkbox. When checked, reveals:
7. **Nickname ẩn danh** — required if anonymous; free text; shown on
   the kudo card instead of the real sender.

Bottom bar: **Huỷ** (cancel) + **Gửi đi** (submit).

This spec absorbs four fold-in frames discovered via overview
comparison:

| Fold-in frame | Role |
|---------------|------|
| `[iOS] Sun*Kudos_Viết Kudo_default` (`7fFAb-K35a`) | Default empty state (anonymous off → Nickname field hidden) |
| `[iOS] Sun*Kudos_Gửi — dropdown hashtag` (`aKWA2klsnt`) | Hashtag picker sub-sheet (confirms **multi-select**) |
| `[iOS] Sun*Kudos_Gửi — dropdown tên người nhận` (`5MU728Tjck`) | Recipient picker sub-sheet (search, single-select) |
| `[iOS] Sun*Kudos_Lỗi chưa điền hết` (`0le8xKnFE_`) | Validation-error state shown when required fields are missing on submit |

---

## Navigation Analysis

### Incoming Navigations (From)

| Source | Trigger | Condition |
|--------|---------|-----------|
| `[iOS] Home` | Tap FAB (Viết Kudo pen icon) | Any time |
| `[iOS] Sun*Kudos` | Tap "Hôm nay, bạn muốn gửi kudos đến ai?" pill | Any time |
| `[iOS] Profile người khác` | Tap "Gửi lời cảm ơn và ghi nhận tới \<Name\>" CTA | **recipientId pre-filled** |
| `[iOS] Thể lệ` | Tap "Viết Kudos" CTA | No prefill |
| `[iOS] Sun*Kudos_All Kudos` | *(likely)* inline compose shortcut | To confirm in All Kudos spec |
| Deep link | `app://kudos/write?recipientId=<id>&hashtag=<tag>` | Any time |

### Outgoing Navigations (To)

| Target | Trigger Element | Node ID | Confidence | Notes |
|--------|-----------------|---------|------------|-------|
| (previous screen) | TopNav Back icon | `6885:9892` | High | Unsaved-changes confirm if draft dirty |
| (previous screen) | Button "Huỷ" | `6885:10003` | High | Same as Back |
| `[iOS] Sun*Kudos_View kudo` | Button "Gửi đi" → success | `6885:10004` | High | On server 201, pop to caller and push View kudo with the new `kudoId` (OR pop twice and land on feed — to confirm with design; this spec assumes **pop + push View kudo** so the user sees what they just sent) |
| **Sub-sheet**: RecipientPickerSheet | Tap recipient search field | `6885:9909` | High | Opens `mms_B_Dropdown-List` overlay |
| **Sub-sheet**: HashtagPickerSheet | Tap hashtag field / "Thêm" | `6885:9940` | High | Opens `Dropdown list hashtag` overlay — multi-select |
| System image picker | Tap "Thêm ảnh" inside `mms_F_Img` | `6885:9987` | High | `PHPickerViewController` wrapped in SwiftUI |
| **UI state**: DefaultEmpty | On first appear, no prefill | `7fFAb-K35a` | High | Fold-in: anonymous off, Nickname field hidden |
| **UI state**: AnonymousOn | User ticks "Gửi ẩn danh" | `6885:9993` | High | Reveals `recipient` frame `6885:9997` (Nickname field) |
| **UI state**: ValidationError | Tap "Gửi đi" with missing fields | `0le8xKnFE_` | High | Fold-in: shows "Bạn cần điền đủ Người nhận, Lời nhắn gửi và Hashtag để gửi Kudos!" |
| (stay) on submit failure | "Gửi đi" → server error | — | High | Toast with retry; form stays populated |

### Navigation Rules

- **Auth required**: Yes.
- **Back / Huỷ** while draft is dirty: present an `.actionSheet` —
  "Bỏ bản nháp?" / "Tiếp tục viết" / "Bỏ".
- **Tab Bar**: visible (pushed above Kudos tab — Tab Bar is there but
  typically covered by the keyboard).
- **Deep link**: `app://kudos/write` (+ optional `recipientId`,
  `hashtag` params for prefill).

---

## Component Schema

### Layout Structure

```
┌─────────────────────────────────────┐
│ StatusBar                            │
├─────────────────────────────────────┤
│ [←]    New Kudo                      │ ← TopNavigation (with title)
├─────────────────────────────────────┤
│ Gửi lời cám ơn và ghi nhận đến       │ ← intro
│ đồng đội                             │
├─────────────────────────────────────┤
│ Người nhận *                         │ ← mms_B.1_Title
│ [ 🔍 Tìm người nhận …           ▼ ]  │ ← mms_B.2_search (opens sub-sheet)
├─────────────────────────────────────┤
│ Danh hiệu *                          │
│ [ Nhập danh hiệu …                ]  │ ← mms_search (free text)
│ Ví dụ: Người truyền động lực cho     │
│ tôi. Danh hiệu sẽ hiển thị làm       │
│ tiêu đề Kudos của bạn.               │
├─────────────────────────────────────┤
│ [B][I][U][…7 tools]                  │ ← mms_C_Chức năng (formatting toolbar)
│ ┌──────────────────────────────────┐ │
│ │ Nội dung kudo…                   │ │ ← mms_D_text filed (rich text area)
│ │                                  │ │
│ └──────────────────────────────────┘ │
│ Bạn có thể "@ + tên" để nhắc tới     │
│ đồng nghiệp khác                     │
├─────────────────────────────────────┤
│ Hashtag *                            │
│ [#Dedicated] [#Inspiring] [+ Add]    │ ← mms_E.2_Tag Group (chips + add → sheet)
├─────────────────────────────────────┤
│ Image                                │
│ [img1][img2][img3][img4][img5][+]    │ ← mms_F (up to 5)
├─────────────────────────────────────┤
│ ☐ Gửi lời cám ơn và ghi nhận ẩn danh │ ← mms_G checkbox
│  ↓ (if ticked)                       │
│ Nickname ẩn danh *                   │
│ [ Nhập nickname …                 ]  │ ← only visible when anonymous=on
├─────────────────────────────────────┤
│ (on submit-with-missing-fields:)     │
│ "Bạn cần điền đủ Người nhận, Lời     │ ← ValidationError fold-in
│  nhắn gửi và Hashtag để gửi Kudos!"  │
├─────────────────────────────────────┤
│   [ Huỷ ]            [ Gửi đi ]      │ ← actions row
├─────────────────────────────────────┤
│ [SAA] [Awards] [Kudos] [Profile]    │ ← Tab Bar (shared)
└─────────────────────────────────────┘
```

### Component Hierarchy

```
WriteKudoScreen (SwiftUI View)
├── TopNavigation (shared)                          # 6885:9888 — title "New Kudo"
├── BackgroundImage (Atom)
├── ComposeForm (Organism, scrollable)
│   ├── IntroLabel (Atom)                           # mms_A
│   ├── LabeledPickerField "Người nhận" *           # recipient frame
│   │   ├── FieldLabel (Atom)
│   │   └── SearchPickerTrigger (Molecule)          # mms_B.2 — taps → RecipientPickerSheet
│   ├── LabeledInputField "Danh hiệu" *
│   │   ├── FieldLabel (Atom)
│   │   └── FreeTextInput (Molecule)                # mms_search (not a picker)
│   ├── HelperText (Atom)                           # mms_B.5
│   ├── KudoBodyEditor (Organism)
│   │   ├── FormattingToolbar (Molecule)            # mms_C_Chức năng (7 buttons)
│   │   └── RichTextArea (Molecule)                 # mms_D_text filed — supports @mention
│   ├── MentionHint (Atom)
│   ├── HashtagField (Organism)                     # mms_E
│   │   ├── FieldLabel (Atom)
│   │   └── HashtagChipList (Molecule)              # chips + add button (sub-sheet)
│   ├── ImageField (Organism)                       # mms_F
│   │   ├── FieldLabel (Atom)
│   │   ├── ImageThumbStrip (Molecule)              # up to 5 images
│   │   └── AddImageButton (Atom)                   # → system picker
│   ├── AnonymousToggle (Molecule)                  # mms_G
│   │   ├── Checkbox (Atom)
│   │   └── Label
│   ├── AnonymousNicknameField (Organism)           # conditional — visible when anonymous
│   │   ├── FieldLabel "Nickname ẩn danh" *
│   │   └── FreeTextInput
│   └── ValidationErrorBanner (Atom)                # conditional — visible on submit-with-errors
└── ActionsBar (Organism, pinned)                   # actions
    ├── SecondaryButton "Huỷ"                       # 6885:10003 → Back
    └── PrimaryButton "Gửi đi"                      # 6885:10004 → submit
```

### Main Components

| Component | Type | Description | Reusable |
|-----------|------|-------------|----------|
| `TopNavigation` | Organism | Shared app-wide | ✅ |
| `LabeledPickerField` | Molecule | Label + tap-to-open-sheet picker | ✅ (recipient + hashtag uses it) |
| `LabeledInputField` | Molecule | Label + single-line free text | ✅ (Danh hiệu + Nickname) |
| `KudoBodyEditor` | Organism | **Novel** — toolbar + rich-text area with @mention | No (compose-only) |
| `HashtagChipList` | Molecule | Chip row with add-button | ✅ (pattern reused on Profile feed if we ever add filter chips) |
| `ImageField` | Organism | Thumb strip + add button, max 5 | ✅ |
| `AnonymousToggle` | Molecule | Checkbox + label | ✅ |
| `ValidationErrorBanner` | Atom | Red text banner above actions | ✅ |
| `ActionsBar` | Organism | Pinned 2-button bar — same pattern as Thể lệ | ✅ (candidate shared) |

---

## Sub-sheets (fold-in)

### RecipientPickerSheet — `[iOS] Sun*Kudos_Gửi — dropdown tên người nhận` (5MU728Tjck)

**Type**: picker sub-sheet (single-select).

- Trigger: tap the "Người nhận" field.
- Contents (`mms_B_Dropdown-List`): a search input at the top plus a
  scrolling list of results. Each row `mms_B.1_kết quả search N` is a
  `Thông tin đồng nghiệp` instance (component `490:5562`) containing:
  - `mms_B.1.1_avatar` (Atom).
  - `mms_B.1.2_tên và đơn vị` (Molecule) — name + department.
- Behaviour:
  - Single-select — picking a row closes the sheet and fills the
    "Người nhận" field with the chosen Sunner.
  - Search input filters results live via `profiles` search
    (min 2 chars; 300 ms debounce).
  - Exclude **self** from results (cannot send Kudos to yourself).
  - Show **"Không tìm thấy Sunner"** empty state when no matches.
- Presentation: `.sheet(isPresented:)` with
  `.presentationDetents([.medium, .large])`.
- Analytics: `write_kudo.recipient_selected`.

### HashtagPickerSheet — `[iOS] Sun*Kudos_Gửi — dropdown hashtag` (aKWA2klsnt)

**Type**: picker sub-sheet (**multi-select** — confirmed).

- Trigger: tap the Hashtag field / "+ Add" chip.
- Contents (`Dropdown list hashtag`): list of tags, each row is:
  - **Selected rows** (`mms_A_Hashtag đã chọn 1..N`): hashtag name +
    checkmark icon (`mms_A.2_icon đã chọn`, component `1002:13201`).
  - **Unselected rows** (`Hashtag chưa chọn`, component `490:5562`): hashtag
    name, no checkmark.
- Behaviour:
  - Multi-select. Tapping toggles selection; sheet stays open.
  - A "Xong" / "Done" action closes the sheet (button TBC — not in
    overview, confirm during `/momorph.specs`).
  - Includes an inline search input (seen in sibling dropdowns elsewhere).
  - If a tag is new (not in list), offer "Tạo hashtag mới" as the last
    row — TBC with product; current design does not show this explicitly.
- Presentation: `.sheet` with `[.medium, .large]` detents.
- Analytics: `write_kudo.hashtag_changed`.

---

## UI States (fold-in)

### DefaultEmpty — `[iOS] Sun*Kudos_Viết Kudo_default` (7fFAb-K35a)

**Type**: default empty state.

First render of the form before the user types anything:

- All fields empty except prefill (e.g. `recipientId` from route param).
- `AnonymousToggle` is **unchecked** → `AnonymousNicknameField` is
  **hidden** (the nested `recipient` frame at the bottom of
  `PV7jBVZU1N` is the post-check state; Viết Kudo_default omits it).
- Text field variant uses `componentId 6885:8801` (placeholder);
  PV7jBVZU1N shows `6885:8806` (filled). Implementation: single field,
  just toggle `placeholder` visibility.
- `ActionsBar`'s primary button "Gửi đi" is **disabled** until at
  least one required field is present (soft gate; real validation on
  tap).

### AnonymousOn

**Type**: state reveal.

- Triggered when the `AnonymousToggle` checkbox is ticked.
- Reveals `AnonymousNicknameField` (the second `recipient` frame
  `6885:9997` in PV7jBVZU1N).
- Field is required when visible; `Gửi đi` gate treats it as such.
- Tick off → field hides and its value is cleared.

### ValidationError — `[iOS] Sun*Kudos_Lỗi chưa điền hết` (0le8xKnFE_)

**Type**: validation error state shown on submit-with-missing-required.

- Triggered by tapping "Gửi đi" while any of these are missing:
  - Người nhận
  - Nội dung (body) — and body ≥ **30 characters** (`KudosConstraints.minCharacterCount`
    from community-standards.md)
  - At least 1 Hashtag
  - If anonymous: Nickname
- Shows inline banner above `ActionsBar` with:
  `"Bạn cần điền đủ Người nhận, Lời nhắn gửi và Hashtag để gửi Kudos!"`
  (extend copy to mention Nickname when anonymous is on).
- Highlights the missing fields' labels in red.
- `Gửi đi` remains enabled so the user can try again after filling.
- Dismisses automatically when all required fields are satisfied.

---

## Form Fields

| Field | Type | Required | Validation | Error key |
|-------|------|----------|------------|-----------|
| Người nhận | `UserID` (via picker) | ✅ | Must be non-self; must be an active Sunner | `write_kudo.error.recipient_missing` |
| Danh hiệu | `String` | ✅ | 3–80 chars | `write_kudo.error.award_missing / too_short` |
| Nội dung | `String` (rich text) | ✅ | **≥ 30 chars** (`KudosConstraints.minCharacterCount`); ≤ 1,000 chars; must not match simple spam patterns (criterion #9 — all punctuation) | `write_kudo.error.body_too_short / spam_detected` |
| Hashtag | `[HashtagID]` | ✅ (min 1) | 1–5 tags | `write_kudo.error.hashtag_missing` |
| Image | `[Attachment]` | optional | Up to 5; each ≤ 5 MB; JPG/PNG/HEIC | `write_kudo.error.image_too_large / bad_format` |
| Gửi ẩn danh | `Bool` | optional | — | — |
| Nickname ẩn danh | `String` | ✅ if anonymous=on | 3–40 chars; no PII patterns | `write_kudo.error.nickname_missing` |

### Validation rules (client-side — mirrors community-standards.md)

```swift
// Derived from KudosSpamCriterion
func clientValidate(_ draft: DraftKudo) -> [KudosValidationError] {
    var errors: [KudosValidationError] = []
    if draft.recipient == nil { errors.append(.recipientMissing) }
    if draft.award.count < 3 { errors.append(.awardTooShort) }
    if draft.body.count < KudosConstraints.minCharacterCount {
        errors.append(.bodyTooShort)      // criterion #7
    }
    if isPunctuationOnly(draft.body) { errors.append(.bodyPunctuationOnly) }  // criterion #9
    if draft.hashtags.isEmpty { errors.append(.hashtagMissing) }
    if draft.isAnonymous && (draft.anonymousNickname ?? "").isEmpty {
        errors.append(.nicknameMissing)
    }
    return errors
}
```

### Rate-limiting rules (client-side guard; server-side authoritative)

- **Bulk send** (criterion #8): enforce ≥ 3 seconds between successful
  submissions. `write_kudo.error.rate_limited` if violated.
- **Repeated similar** (criterion #6): tracked server-side; client
  surfaces the server's rejection as a toast.

---

## API Mapping

Backend: **Supabase**.

### On Screen Load / Resume

| Call | Method | Purpose |
|------|--------|---------|
| `supabase.auth.getSession()` | SDK | Auth guard |
| *(if `recipientId` prefill)* `supabase.from("profiles").select("*").eq("user_id", recipientId).single()` | GET | Populate the Người nhận field display |
| `supabase.from("hashtags").select(...)` | GET | First-load for HashtagPickerSheet (cached for 5 min) |

### On User Action

| Action | Call | Method | Request | Response |
|--------|------|--------|---------|----------|
| Open RecipientPickerSheet → search | `supabase.from("profiles").select(...).ilike("full_name", "%q%").neq("user_id", uid).limit(20)` | GET | `{ q }` | Result list |
| Select recipient | — | local | — | Close sheet + fill field |
| Open HashtagPickerSheet | (cached list or refetch) | — | — | — |
| Toggle hashtag | — | local | — | Update chip list |
| Add image | System PHPicker → upload | `POST /storage/v1/object/kudo_attachments/{uid}/{uuid}.ext` | Multipart | Storage URL / object id |
| Remove image | `DELETE /storage/v1/object/kudo_attachments/{...}` | DELETE | — | — |
| Toggle anonymous | — | local | — | Reveal/hide Nickname field |
| Submit **Gửi đi** | `supabase.from("kudos").insert(draft).select().single()` | POST | `{ recipient_id, award_title, body, hashtag_ids, attachment_urls, is_anonymous, anonymous_nickname }` | `{ id, … }` |
| On success | — | navigation | — | Pop + push View kudo (new id) |
| On spam-classified (server) | server returns `status = 'soft_hidden'` on the created row | — | — | Show toast "Kudos đã được gửi, nhưng cần rà soát vì bị nghi vi phạm tiêu chuẩn. Xem Tiêu chuẩn cộng đồng." + link to `[iOS] Tiêu chuẩn cộng đồng` |

### Error Handling

| Error | Source | UI action |
|-------|--------|-----------|
| Session expired | Guard | Redirect to Login |
| Recipient search failed | REST | Sheet-level retry row |
| Upload failed | Storage 5xx | Retry the specific image; mark failed ones in the strip |
| Submit validation errors | `clientValidate()` | Render `ValidationErrorBanner` fold-in state |
| Submit rate-limited (client) | Timer | Toast "Gửi quá nhanh. Thử lại sau X giây." |
| Submit 4xx (server validation) | REST | Toast with server message (ideally mapped from a stable `code`) |
| Submit 5xx | REST | Toast + retry affordance; form stays populated |
| Submit returns `soft_hidden` | REST | Info toast as above; still pops + pushes View kudo (the author sees their own soft-hidden kudo) |

---

## State Management

### Local State (ViewModel — Principle III)

```swift
protocol WriteKudoViewModel {
    init(prefilledRecipient: UserID?)         // from route param

    // Inputs
    var viewAppeared: PublishRelay<Void> { get }
    var recipientFieldTapped: PublishRelay<Void> { get }
    var recipientSelected: PublishRelay<UserID> { get }
    var awardTitleChanged: PublishRelay<String> { get }
    var bodyChanged: PublishRelay<String> { get }
    var toolbarAction: PublishRelay<ToolbarAction> { get }   // bold/italic/mention/…
    var hashtagFieldTapped: PublishRelay<Void> { get }
    var hashtagToggled: PublishRelay<HashtagID> { get }
    var imageAdded: PublishRelay<PHAsset> { get }
    var imageRemoved: PublishRelay<AttachmentID> { get }
    var anonymousToggled: PublishRelay<Bool> { get }
    var anonymousNicknameChanged: PublishRelay<String> { get }
    var cancelTapped: PublishRelay<Void> { get }
    var submitTapped: PublishRelay<Void> { get }

    // Outputs
    var recipient: Driver<ProfileChipVM?> { get }
    var awardTitle: Driver<String> { get }
    var body: Driver<AttributedString> { get }
    var hashtags: Driver<[HashtagChipVM]> { get }
    var attachments: Driver<[AttachmentVM]> { get }    // up to 5
    var isAnonymous: Driver<Bool> { get }
    var anonymousNickname: Driver<String> { get }
    var validationErrors: Driver<[KudosValidationError]> { get }
    var isSubmitting: Driver<Bool> { get }
    var submitEnabled: Driver<Bool> { get }
    var presentSheet: Signal<ComposeSheet> { get }     // .recipient | .hashtag
    var presentImagePicker: Signal<Void> { get }
    var navigate: Signal<AppRoute> { get }             // .pop + .viewKudo(id)
    var toast: Signal<ToastVM> { get }
    var confirmDiscard: Signal<Void> { get }
}
```

### Draft model

```swift
struct DraftKudo: Equatable {
    var recipient: UserID?
    var awardTitle: String = ""
    var body: String = ""
    var hashtagIds: Set<HashtagID> = []
    var attachments: [AttachmentID] = []
    var isAnonymous: Bool = false
    var anonymousNickname: String = ""

    var isDirty: Bool { self != DraftKudo() || !attachments.isEmpty }
}
```

### Global State

| State | Store | R/W | Purpose |
|-------|-------|-----|---------|
| `AuthState` | `AuthStore` | R | Guard + exclude self in recipient search |
| `HashtagCatalog` | local cache | R | First-load + optional refresh |

No write to global state on success — the new kudo will appear
naturally in feeds via queries; unread count on Home is server-driven.

---

## UI States (master list)

### Loading State

- First-load recipient prefill: skeleton chip in the "Người nhận" field.
- HashtagPickerSheet: skeleton rows while initial list loads.
- During submit: primary button shows a spinner; all fields disabled.
- During image upload: each thumb shows a circular progress overlay.

### Error State

- See fold-in `ValidationError` (above) for client-side.
- Server 4xx/5xx → toast.
- Image upload error → inline "!" on the failed thumb with retry tap.

### Success State

- Submit → primary button spinner → success haptic → pop + push View
  kudo with the new `kudoId`.

### Empty State

- Default empty (covered by `DefaultEmpty` fold-in).

---

## Accessibility (Principle II)

| Requirement | Implementation |
|-------------|----------------|
| Screen context | Announce `"Viết Kudo"` on appear |
| Required fields | Each required label ends with `"*"` and the VoiceOver label expands to `"\(field), bắt buộc"` |
| Recipient picker | Trigger `.isButton`; hint `"Mở danh sách Sunner"` |
| Rich-text editor | Uses a `UIViewRepresentable` around `UITextView` to get native VoiceOver + keyboard accessory; toolbar buttons expose labels like `"In đậm"`, `"Nghiêng"`, `"Gạch chân"`, `"Đề cập đồng nghiệp"` — exact set confirmed during `/momorph.specs` |
| Hashtag chips | Each chip is `.isButton`; selected chips add `.isSelected`; "Thêm" button `"Thêm hashtag"` |
| Image strip | Each image `"Ảnh \(n) / 5"`; remove action exposed as a custom action |
| Anonymous toggle | Announce state change: `"Gửi ẩn danh, bật"` / `"tắt"` |
| Validation banner | `.accessibilityAddTraits(.isStaticText)` + `.accessibilityLiveRegion(.polite)` so VoiceOver reads it when it appears |
| Touch targets | All inputs ≥ 44 pt tall; chips ≥ 44 pt; remove buttons on images ≥ 44×44 |
| Dynamic Type | Long prose wraps; form fields grow vertically at AX3+ |
| Localisation | VN + EN keys for all labels and errors |

---

## Responsive Behavior

| Device class | Layout |
|--------------|--------|
| iPhone portrait | As designed; body field auto-grows up to ~8 lines |
| iPhone landscape | Scrollable form; keyboard overlays lower third; ActionsBar stays visible above the keyboard (`.keyboardAvoiding()`) |
| iPad | Max width 600 pt centered |
| AX3+ | Chips reflow; actions stack vertically |

---

## Analytics Events (Optional)

| Event | Trigger | Properties |
|-------|---------|------------|
| `write_kudo.viewed` | On appear | `{ source, has_prefill }` |
| `write_kudo.recipient_opened` | Open picker | — |
| `write_kudo.recipient_selected` | Pick row | — (no user_id logged) |
| `write_kudo.hashtag_opened` | Open picker | — |
| `write_kudo.hashtag_changed` | Toggle | `{ count }` |
| `write_kudo.image_added` | Add | `{ image_count }` |
| `write_kudo.anonymous_toggled` | Checkbox | `{ on }` |
| `write_kudo.submit_tap` | Submit | `{ body_length_bucket, hashtag_count, image_count, is_anonymous }` |
| `write_kudo.validation_failed` | Client validation | `{ errors: [codes] }` |
| `write_kudo.submit_success` | Server 201 | `{ status }` — `active` or `soft_hidden` |
| `write_kudo.submit_failed` | Server 4xx/5xx | `{ code }` |
| `write_kudo.discard` | Cancel with dirty draft | — |

Never log body, recipient name/id, or nickname (Principle V).

---

## Design Tokens

| Token | Usage |
|-------|-------|
| `Color("FieldBG")` | Input backgrounds |
| `Color("FieldBorder")` | Input borders |
| `Color("LabelRequired")` | Red asterisks |
| `Color("ChipBG")` | Hashtag chips |
| `Color("ChipSelectedBG")` | Selected chips in picker |
| `Color("ErrorText")` | Validation banner |
| `Color("BrandPrimary")` | "Gửi đi" |
| `Color("BrandSecondary")` | "Huỷ" |
| Font: `.headline` → labels; `.body` → inputs; `.callout` → helper text; `.footnote` → mention hint |
| SF Symbols: `checkmark` (checkmark icon for selected hashtag), `plus.circle.fill` (add image), `paperplane.fill` (Gửi đi) |

---

## Implementation Notes

### Clean Architecture touch-points (Principle I)

- **Presentation**:
  `Presentation/WriteKudo/Views/WriteKudoView.swift`,
  `Presentation/WriteKudo/ViewModels/WriteKudoViewModel.swift`,
  `Presentation/WriteKudo/ViewModels/WriteKudoStateAdapter.swift`,
  `Presentation/WriteKudo/Components/KudoBodyEditor.swift`,
  `Presentation/WriteKudo/Components/HashtagChipListView.swift`,
  `Presentation/WriteKudo/Components/ImageFieldView.swift`,
  `Presentation/WriteKudo/Components/AnonymousToggleView.swift`,
  `Presentation/WriteKudo/Components/RecipientPickerSheet.swift`,
  `Presentation/WriteKudo/Components/HashtagPickerSheet.swift`,
  `Presentation/WriteKudo/Components/ValidationErrorBanner.swift`,
  `Presentation/Shared/Components/LabeledPickerField.swift`,
  `Presentation/Shared/Components/LabeledInputField.swift`,
  `Presentation/Shared/Components/ActionsBar.swift` (consolidated with Thể lệ's pattern).
- **Domain**:
  `Domain/UseCases/SearchSunnersUseCase.swift`,
  `Domain/UseCases/FetchHashtagsUseCase.swift`,
  `Domain/UseCases/UploadAttachmentUseCase.swift`,
  `Domain/UseCases/SubmitKudoUseCase.swift`,
  `Domain/Entities/DraftKudo.swift`,
  `Domain/Entities/KudosValidationError.swift` (mirrors `KudosSpamCriterion`),
  `Domain/Entities/Hashtag.swift` (reused from sun-kudos.md),
  `Domain/Entities/Attachment.swift`.
- **Data**:
  `Data/Repositories/KudoRepositoryImpl.swift` — extend with `submit`,
  `Data/Repositories/HashtagRepositoryImpl.swift` (reused),
  `Data/Repositories/AttachmentRepositoryImpl.swift`,
  `Data/Remote/Kudos/KudoSubmitDTO.swift`,
  `Data/Remote/Attachments/SupabaseStorageClient.swift`.

### Reactive model (Principle III)

- **Draft synthesis**: `combineLatest` of the seven input streams →
  `Observable<DraftKudo>` → `BehaviorRelay<DraftKudo>`.
- **submitEnabled**: `draftRelay.map { $0.isDirty && !isSubmitting }`.
- **submitTapped**:
  ```swift
  submitTapped
      .withLatestFrom(draftRelay) { _, draft in draft }
      .flatMapLatest { draft -> Observable<Result<Kudo, KudoError>> in
          let clientErrors = validator.validate(draft)
          guard clientErrors.isEmpty else {
              validationErrorsRelay.accept(clientErrors)
              return .empty()
          }
          return repo.submit(draft).asObservable().materialize().map { ... }
      }
      .subscribe(onNext: handleResult)
      .disposed(by: bag)
  ```
- **Cancel-with-dirty**: `cancelTapped.withLatestFrom(draftRelay)` →
  if dirty, emit `confirmDiscard`; the View shows an action sheet that
  re-emits a confirmed cancel back into the pipe.

### Security (Principle V)

- RLS on `kudos`:
  - `INSERT with check (sender_id = auth.uid())` — client cannot
    impersonate another sender.
  - `SELECT` policy constrains visibility (see other Kudos specs).
- Storage bucket `kudo_attachments`:
  - `policy "owner can insert" using (auth.uid()::text = (storage.foldername(name))[1])`
  - `policy "public can read"` ONLY if kudos are intended to be public
    — else restrict to authenticated users.
- Validate attachment MIME server-side too (don't trust client MIME).
- Never log body / recipient / nickname.
- `@mention` parsing: server resolves `@username` → `user_id` at insert
  time; do not trust client's resolution.

### Edge cases

- Prefill `recipientId` that doesn't exist → show empty field + silent
  log; don't block the user.
- User backgrounds the app mid-compose → draft kept in memory only for
  v1 (no disk persistence). Out-of-scope for v1; flag for later if
  abandon-rate is high.
- Paste into body exceeds 1,000 chars → truncate + toast.
- Anonymous nickname collision with a real Sunner's name → allowed
  (nicknames are not unique identifiers); analytics may note the
  collision.
- User tries to `@mention` the recipient → allowed.

---

## Analysis Metadata

| Property | Value |
|----------|-------|
| Analyzed By | `/momorph.screenflow` |
| Analysis Date | 2026-04-24 |
| Source | `get_overview` on 5 frames: `PV7jBVZU1N` (parent, depth 5) + `7fFAb-K35a` (default state — verified to fold), `aKWA2klsnt` (hashtag picker sub-sheet), `5MU728Tjck` (recipient picker sub-sheet), `0le8xKnFE_` (validation error state) |
| Verify result (`7fFAb-K35a`) | ✅ **Folded** — ≥ 95% layout similarity; only difference is anonymous toggle state |
| Needs Deep Analysis | The 7-button `FormattingToolbar` — exact actions to resolve during `/momorph.specs`. The "+ Add hashtag" UX (create-new vs only-pick) to confirm. |
| Confidence Score | High for form structure + validation; Medium for toolbar semantics and hashtag-create flow |

### Next Steps

- [ ] Confirm the **7 toolbar actions** (B / I / U / S / list / link /
      @mention / emoji / image — pick 7) during `/momorph.specs`.
- [ ] Confirm whether hashtags can be **created** from the picker or
      only selected from a catalog.
- [ ] Confirm the "Gửi đi" success path: does it pop to Kudos feed OR
      push View kudo? This spec assumes **push View kudo**.
- [ ] Confirm max image size + accepted formats with backend for
      Supabase Storage bucket config.
- [ ] Add `kudos` and `kudo_attachments` RLS + bucket policy seeds in
      `/momorph.database`.
- [ ] Extract `ActionsBar` + `LabeledPickerField` + `LabeledInputField`
      + `ValidationErrorBanner` as shared components in
      `Presentation/Shared/` during implementation.
