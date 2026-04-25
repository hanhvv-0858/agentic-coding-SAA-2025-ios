# Screen: [iOS] Sun*Kudos_Tiêu chuẩn cộng đồng

## Screen Info

| Property | Value |
|----------|-------|
| **Figma Frame ID** | `xms7csmDhD` (node `6885:10806`) |
| **Figma Link** | https://momorph.ai/files/9ypp4enmFmdK3YAFJLIu6C/screens/xms7csmDhD |
| **Screen Group** | Static content (rules) |
| **Platform** | iOS (SwiftUI) |
| **Status** | discovered |
| **Discovered At** | 2026-04-24 |
| **Last Updated** | 2026-04-24 |

---

## Description

`[iOS] Sun*Kudos_Tiêu chuẩn cộng đồng` is a **static long-form reference
screen** spelling out the rules Sunners must follow when writing
Kudos — what counts as "Spam" (content moderation criteria) and what
information security expectations apply. Navigated to from the
Notifications row N5 ("content soft-hidden") inline CTA and (likely)
from the Kudos tab / Gửi lời chúc compose screen.

Content structure:

1. **Cover + KV image**.
2. **Tiêu chuẩn cộng đồng** — Community Standards:
   - Intro paragraph.
   - **10 Spam criteria** (triggers that soft-hide a kudo — see below).
3. **Tiêu chuẩn bảo mật** — Security Standards:
   - Information security commitment.
   - Scope-of-sharing guidance ("internal Sun\* only").
   - Contact: **BTC SAA representative — Slack `duong.thi.thuy.an`**.

There is **no action bar / CTA** on this screen — only a Back icon.

> Design inconsistency: the TopNavigation title reads **"Tiêu chuẩn
> chung"** but the frame name and the section headings read **"Tiêu chuẩn
> cộng đồng"**. Flagged for design to unify. This spec uses the
> frame-level naming (`"Tiêu chuẩn cộng đồng"`) for keys and labels.

### Canonical 10-criterion Spam taxonomy

These are the authoritative rules for a Kudos being soft-hidden by the
system (matches Notification N5 "Tiếc quá! Bạn có một lời nhắn bị tạm ẩn…"):

| # | Criterion (VN-original) | Impl consideration |
|---|-------------------------|--------------------|
| 1 | Từ ngữ thô tục, chửi bậy, nội dung xúc phạm, bôi nhọ | Server-side profanity / toxicity classifier |
| 2 | Chính trị, tôn giáo, phân biệt giới tính | Server-side classifier |
| 3 | Số liệu cụ thể (doanh thu, hợp đồng, KPI, khách hàng, mã dự án, số tài khoản…) | Server-side pattern match |
| 4 | Tên đối tác, khách hàng, tổ chức bên ngoài | Server-side NER / blocklist |
| 5 | Thông tin cá nhân (email, số điện thoại, địa chỉ, thông tin gia đình) | Server-side PII detector |
| 6 | Gửi lặp lại 3+ tin nhắn có nội dung tương tự nhau trong thời gian ngắn | Server-side rate / similarity heuristic |
| 7 | Kudos **quá ngắn (dưới 30 ký tự)**, không có ngữ cảnh (ví dụ: "Cảm ơn nhiều", "Thanks nhé", "Good job!") | **Client-side minLength = 30** + server-side re-check |
| 8 | Gửi cho quá nhiều người trong thời gian ngắn (<3s/lời nhắn) | Server-side rate limit |
| 9 | Chỉ chứa ký tự `.`, `,`, `...` hoặc ký tự không có nội dung | Client hint + server regex |
| 10 | "Tim" tăng đột biến bất thường (hành vi vote-farm) | Server-side anomaly detection |

Capture these in a Domain-layer `KudosSpamCriterion` enum so Gửi lời
chúc's inline hints and the server-side moderation pipeline share the
same source of truth.

---

## Navigation Analysis

### Incoming Navigations (From)

| Source | Trigger | Condition |
|--------|---------|-----------|
| `[iOS] Notifications` N5 (soft-hidden) | Row tap OR inline CTA "Xem tiêu chuẩn cộng đồng" | Any time |
| `[iOS] Sun*Kudos` | Rules / Standards link inside the Kudos tab | Medium — confirm during Wave 5 |
| `[iOS] Sun*Kudos_Gửi lời chúc Kudos` | Optional "View standards" link near the input field | Medium — confirm during Wave 5 |
| Deep link | `app://community-standards` | Any time |

### Outgoing Navigations (To)

| Target | Trigger | Node ID | Confidence | Notes |
|--------|---------|---------|------------|-------|
| (previous screen) | Back Icon | `6885:10825` | High | Standard `NavigationStack` pop — only affordance on this screen |

Optional external action (not wired in design but reasonable for
implementation): tap on the Slack handle `duong.thi.thuy.an` opens the
Slack app via deep link `slack://user?team=<T>&id=<U>`. Since the team
ID is not captured in design, this is deferred.

### Navigation Rules

- **Auth required**: Yes (content is internal; see "scope of sharing"
  paragraph).
- **Back behavior**: pop to caller.
- **Deep link**: `app://community-standards`.
- **Tab Bar**: visible (pushed above the current tab).

---

## Component Schema

### Layout Structure

```
┌─────────────────────────────────────┐
│ StatusBar                            │
├─────────────────────────────────────┤
│ [←]    Tiêu chuẩn chung              │ ← TopNavigation (title inconsistency flagged)
├─────────────────────────────────────┤
│ [========== Cover + KV ============] │ ← 6885:10831 + 10828
├─────────────────────────────────────┤
│  Tiêu chuẩn cộng đồng                │ ← mms_B title
│                                      │
│  Tiêu chuẩn Cộng đồng được xây…      │ ← intro
│                                      │
│  Các nội dung phát hiện có một       │ ← spam-criteria heading
│  trong những tiêu chí vi phạm bên    │
│  dưới sẽ được gắn nhãn Spam và       │
│  được hệ thống chủ động ẩn.          │
│                                      │
│  • Sử dụng từ ngữ thô tục …          │ ← 10 bullet points
│  • Đề cập chính trị, tôn giáo …      │
│  • …                                 │
│  ────────────                        │
│                                      │
│  Tiêu chuẩn bảo mật                  │ ← mms_C title
│  Sunner cam kết bảo vệ thông tin …   │
│  Bảo mật Thông tin: …                │
│  Phạm vi Chia sẻ: …                  │
│                                      │
│  Liên hệ Hỗ trợ: Slack               │
│  duong.thi.thuy.an                   │
│                                      │
└─────────────────────────────────────┘
```

### Component Hierarchy

```
CommunityStandardsScreen (SwiftUI View)
├── TopNavigation (shared)                             # 6885:10810
│   └── Title "Tiêu chuẩn chung" (flagged inconsistency)
├── BackgroundImage (Atom)
├── CoverAndKV (Organism)                              # 6885:10831 + 10828
│   ├── CoverImage (Atom)
│   └── KeyVisualImage (Atom)
└── ScrollableRulesContent (Organism)                  # 6885:10832
    ├── CommunityStandardsSection (Organism)           # mms_B
    │   ├── Title "Tiêu chuẩn cộng đồng"
    │   ├── IntroParagraph (Atom)
    │   ├── SpamCriteriaIntro (Atom)
    │   └── BulletList (Molecule)
    │       └── BulletListItem ×10 (one per criterion)
    ├── Divider                                        # Rectangle 19
    └── SecurityStandardsSection (Organism)            # mms_C
        ├── Title "Tiêu chuẩn bảo mật"
        ├── SecurityParagraph (Atom)
        ├── ScopeParagraph (Atom)
        └── ContactParagraph (Atom)                    # incl. Slack handle
```

### Main Components

| Component | Type | Node ID | Description | Reusable |
|-----------|------|---------|-------------|----------|
| `TopNavigation` | Organism | `6885:10810` | App-wide shared | ✅ |
| `ScrollableRulesContent` | Organism | `6885:10832` | **Same prose-rendering pattern** as Thể lệ's `ScrollableRulesContent` — consider extracting a shared `RulesDocumentView` | ✅ candidate for shared |
| `BulletList` + `BulletListItem` | Molecule / Atom | — | New reusable list pattern with localised bullet strings | ✅ — small, generic |

Suggested shared refactor: introduce a `RulesDocumentView` that both
`[iOS] Thể lệ` and this screen consume, parameterised by:

```swift
struct RulesDocumentViewModel {
    let sections: [RulesSection]              // ordered
}

enum RulesSection {
    case header(LocalizedStringKey)
    case paragraph(LocalizedStringKey)
    case bulletList([LocalizedStringKey])
    case divider
    case heroTierList                         // Thể lệ only
    case badgeShowcase                        // Thể lệ only
    case actionsBar(primary: Action, secondary: Action?)   // Thể lệ only
}
```

Actions bar is omitted here because this screen has no CTA.

---

## Form Fields (If Applicable)

Not applicable.

---

## API Mapping

**No API calls for v1** — same static-content pattern as [the-le.md](the-le.md).

- Option A (recommended v1): all strings bundled in `Localizable.xcstrings`.
- Option B (v-next): fetch from a Supabase `rules` table with
  `key = "community_standards_v1"` and a stable-sortable structure.

### On User Action

| Action | Call | Method | Request | Response |
|--------|------|--------|---------|----------|
| Tap Back | — | navigation | — | Pop |
| Tap Slack handle (proposed, v-next) | `UIApplication.open(URL("slack://..."))` | local | — | Falls back to Safari if Slack not installed |

---

## State Management

### Local State (ViewModel — Principle III)

Minimal — the screen is effectively static. The ViewModel exists only
for Rx consistency:

```swift
protocol CommunityStandardsViewModel {
    // Inputs
    var closeTapped: PublishRelay<Void> { get }

    // Outputs
    var navigate: Signal<AppRoute> { get }        // only emits `.pop`
}
```

### Global State

| State | Store | R/W | Purpose |
|-------|-------|-----|---------|
| `AuthState` | `AuthStore` | R | Defensive guard on appear (content is internal-only) |

---

## UI States

### Loading State

N/A in v1 (static content).

### Error State

N/A in v1.

### Success State

All prose rendered; scroll natural.

### Empty State

N/A.

---

## Accessibility (Principle II)

| Requirement | Implementation |
|-------------|----------------|
| Screen title | Announce `"Tiêu chuẩn chung"` (or the resolved localised title) on appear |
| Reading order | Intro → Spam criteria list → Security section → Contact |
| Bullet list | Each item is an individual accessibility element; VoiceOver reads "Mục 1 của 10: …" via `.accessibilityLabel` |
| Contact paragraph | Slack handle should be a separate accessibility element with `.isLink` trait so users can tap through |
| Dynamic Type | Prose + bullets scale to AX5; no truncation |
| Touch targets | Back ≥ 44×44; Slack handle ≥ 44 pt if made tappable |
| Reduced motion | No motion |
| Localisation | VN + EN keys for every criterion and paragraph |

---

## Responsive Behavior

| Device class | Layout |
|--------------|--------|
| iPhone portrait | As designed |
| iPhone landscape | Cover shrinks; content scrolls |
| iPad | Max width 600 pt, centered |

---

## Analytics Events (Optional)

| Event | Trigger | Properties |
|-------|---------|------------|
| `community_standards.viewed` | On appear | `{ source }` — `notifications.n5 / sun_kudos.link / write_kudo.link / deeplink` |
| `community_standards.back` | Back tap | `{ source }` |
| `community_standards.slack_tap` | Slack handle tap (if wired) | `{ source }` |

---

## Design Tokens

| Token | Usage |
|-------|-------|
| `Color("TextPrimary")` | Body + list items |
| `Color("TextSecondary")` | Intro paragraph |
| `Color("LinkText")` | Slack handle (if made tappable) |
| Font: `.title2` → section titles (Tiêu chuẩn cộng đồng, Tiêu chuẩn bảo mật), `.body` → prose, `.body` with bullet marker → criteria list |
| Asset: `Image("community_standards_cover")`, `Image("community_standards_kv")` — resolve via `/momorph.specs` |

---

## Implementation Notes

### Clean Architecture touch-points (Principle I)

- **Presentation**: `Presentation/Rules/Views/CommunityStandardsView.swift`,
  `Presentation/Rules/ViewModels/CommunityStandardsViewModel.swift`.
- **Shared**: if the refactor is accepted,
  `Presentation/Shared/Components/RulesDocumentView.swift` consumed by
  both Thể lệ and this screen.
- **Domain**: introduce a `KudosSpamCriterion` enum so Gửi lời chúc's
  validation and the server-side moderation pipeline share identifiers:

  ```swift
  enum KudosSpamCriterion: String, CaseIterable, Codable {
      case profanity, politicsReligionDiscrimination,
           specificBusinessData, externalOrgNames, personalInfo,
           repeatedSimilarMessages, tooShort, bulkSend,
           emptyPunctuation, unusualHeartSpike

      var localizedKey: LocalizedStringKey { "spam.criterion.\(rawValue)" }
  }
  ```
- **Data**: none.

### Domain constants surfaced

Add alongside Thể lệ's `Mechanic` constants:

```swift
enum KudosConstraints {
    static let minCharacterCount = 30          // criterion #7
    static let bulkSendMinInterval: TimeInterval = 3   // criterion #8
    static let repeatedSimilarThreshold = 3    // criterion #6
}
```

The client-side validator uses `minCharacterCount` on Gửi lời chúc to
block submissions under 30 chars with an inline error (prevents many N5
notifications in the first place).

### Reactive model (Principle III)

- Single `Signal<AppRoute>` mapped from `closeTapped` → `.pop`.

### Security (Principle V)

- Content is **internal-only** by explicit statement ("vui lòng chỉ chia
  sẻ trong nội bộ Sun\*"). The screen itself is not a security boundary;
  authentication gates this content.
- Slack handle is a contact — non-sensitive but should not be logged in
  analytics beyond a hashed/short-code form.

### Edge cases

- User reaches here while offline — Option A renders instantly.
- Slack deep link not installed — fall back to a web URL (also deferred
  pending product decision; out of v1 scope).
- Localisation mismatch: the title "Tiêu chuẩn chung" vs. the body "Tiêu
  chuẩn cộng đồng" — reconcile in design before shipping; do not paper
  over with code logic.

---

## Analysis Metadata

| Property | Value |
|----------|-------|
| Analyzed By | `/momorph.screenflow` |
| Analysis Date | 2026-04-24 |
| Source | `get_overview` on `xms7csmDhD` (depth 5) |
| Needs Deep Analysis | No |
| Confidence Score | High — pure static content |

### Next Steps

- [ ] Resolve title inconsistency with design: **"Tiêu chuẩn chung"** vs
      **"Tiêu chuẩn cộng đồng"**. Pick one, update frame name AND title.
- [ ] Decide Slack deep link behaviour (in scope / out of scope / open
      as web URL).
- [ ] Lock in `KudosSpamCriterion` enum + `KudosConstraints` values
      (`minCharacterCount = 30`) — these will be consumed by
      `[iOS] Sun*Kudos_Gửi lời chúc Kudos` validator in Wave 5.
- [ ] Consider extracting `RulesDocumentView` shared component during
      implementation — refactor `[iOS] Thể lệ` at the same time.
- [ ] Confirm entry points inside Kudos tab (during Wave 5 Sun*Kudos
      analysis).
