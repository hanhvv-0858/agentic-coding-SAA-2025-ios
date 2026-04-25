# Screen: [iOS] Award Detail (merged — 6 content variants)

## Screen Info

| Property | Value |
|----------|-------|
| **Primary Figma Frame** | `c-QM3_zjkG` ([iOS] Award_Top talent — latest revision) |
| **Figma Link** | https://momorph.ai/files/9ypp4enmFmdK3YAFJLIu6C/screens/c-QM3_zjkG |
| **Screen Group** | Awards cluster (SAA 2025) |
| **Platform** | iOS (SwiftUI) |
| **Status** | discovered (all 6 variants in one spec) |
| **Discovered At** | 2026-04-24 |
| **Last Updated** | 2026-04-24 |

### Content variants — 6 awards, 1 logical screen

All 6 frames share **identical** structure (`get_overview` depth 4 compared
on 3 frames — MVP / Top project / Top talent — confirmed). They collapse
to a single `AwardDetailView` parameterised by an `AwardKind` enum.

| # | Award | Frame ID | Figma |
|---|-------|----------|-------|
| 1 | MVP | `b2BuS8HYIt` | [open](https://momorph.ai/files/9ypp4enmFmdK3YAFJLIu6C/screens/b2BuS8HYIt) |
| 2 | Best Manager | `7y195PPTxQ` | [open](https://momorph.ai/files/9ypp4enmFmdK3YAFJLIu6C/screens/7y195PPTxQ) |
| 3 | Signature 2025 — Creator | `O98TwiHaJe` | [open](https://momorph.ai/files/9ypp4enmFmdK3YAFJLIu6C/screens/O98TwiHaJe) |
| 4 | Top project | `FQoJZLkG_d` | [open](https://momorph.ai/files/9ypp4enmFmdK3YAFJLIu6C/screens/FQoJZLkG_d) |
| 5 | Top project leader | `QQvsfK3yaK` | [open](https://momorph.ai/files/9ypp4enmFmdK3YAFJLIu6C/screens/QQvsfK3yaK) |
| 6 | Top talent | `c-QM3_zjkG` | [open](https://momorph.ai/files/9ypp4enmFmdK3YAFJLIu6C/screens/c-QM3_zjkG) |

### Per-variant data

Each `AwardKind` carries content — description text, artwork asset,
numeric stats, localisation keys. The data table is canonical truth for
the implementation; values below come from the Figma `get_overview`.

| AwardKind | Artwork component | Description (VN excerpt) |
|-----------|-------------------|--------------------------|
| `.mvp` | `mm_media_Picture-Award` (component `6885:8049`) | "Giải thưởng MVP vinh danh cá nhân xuất sắc nhất năm – gương mặt tiêu biểu đại diện cho toàn bộ tập thể Sun\*…" |
| `.bestManager` | — *(resolve via `/momorph.specs`)* | (content TBD — `get_overview` on frame `7y195PPTxQ` when implementing) |
| `.signatureCreator` | — | (TBD) |
| `.topProject` | `mm_media_Picture-Award` (component `6885:8040`) | "Giải thưởng Top Project vinh danh các tập thể dự án xuất sắc với kết quả kinh doanh vượt kỳ vọng…" |
| `.topProjectLeader` | — | (TBD) |
| `.topTalent` | `mm_media_Picture-Award` (component `6885:8037`) | "Giải thưởng Top Talent vinh danh những cá nhân xuất sắc toàn diện – những người không ngừng khẳng định năng lực chuyên môn vững vàng…" |

Content for 3 remaining variants (`.bestManager`, `.signatureCreator`,
`.topProjectLeader`) is extracted during `/momorph.specs` runs; it does
**not** change this spec's structure.

---

## Description

`[iOS] Award detail` is a **read-only information screen** that
explains one SAA 2025 award category. It is reachable from:

- `[iOS] Home` — tapping **"Chi tiết"** on any of the 3 award teaser
  cards (Top Talent / Top Project / Top Project Leader).
- The as-yet-unmapped `Awards` tab destination (to confirm during any
  future Awards-tab analysis).
- Deep links (`app://awards/:kind`).

Structure:

1. Shared `HomeHeader` (logo + language + search + notification bell).
2. `KV Kudos` key-visual banner — "Hệ thống ghi nhận và cảm ơn".
3. `Highlight` header with filter affordance (likely **year selector**
   for historical winners — medium confidence; confirm during
   `/momorph.specs`).
4. `Award` block:
   - Artwork (`Picture-Award`, kind-specific).
   - Title + long-form description (kind-specific).
   - Divider.
   - Numeric stat row (labelled "title / number" in Figma — likely
     **prize count** / **budget** / **past-winner count**; confirm).
   - Divider.
   - Second numeric stat row (same pattern).
5. `Kudos` block (static brand content repeated across all 6):
   - Header "Phong trào ghi nhận" / "Sun\*Kudos".
   - Kudos banner artwork.
   - Note: "ĐIỂM MỚI CỦA SAA 2025 — Hoạt động ghi nhận và cảm ơn đồng
     nghiệp…". Button **"Chi tiết"** → `[iOS] Sun*Kudos` feed.
6. Shared `BottomTabBar` (4 tabs).

All copy-level differences are encoded in `AwardKind`; all structural
layout is shared across the 6 frames.

---

## Navigation Analysis

### Incoming Navigations (From)

| Source | Trigger | Condition |
|--------|---------|-----------|
| `[iOS] Home` | Tap "Chi tiết" on Top Talent / Top Project / Top Project Leader card | `awardKind` derived from the tapped card |
| Awards tab (TBC destination) | Tap on a list row | — |
| Deep link | `app://awards/:kind` | Any time |

### Outgoing Navigations (To)

| Target | Trigger | Node ID (MVP example) | Confidence | Notes |
|--------|---------|-----------------------|------------|-------|
| `[iOS] Language dropdown` | Language chip | `I6885:10737;88:1829` | High | Shared fold-in |
| `[iOS] Sun*Kudos_Search Sunner` (TBC) | Search icon | `I6885:10737;88:1869` | Medium | |
| `[iOS] Notifications` | Bell icon | `I6885:10737;88:1830` | High | |
| `[iOS] Sun*Kudos` (`fO0Kt19sZZ`) | Button "Chi tiết" under the Kudos block | `6885:10804` | High | Opens Kudos feed |
| Tab switch | Tab Bar | `6885:10805` | High | |

### Navigation Rules

- **Auth required**: Yes.
- **Back behavior**: pop to whatever pushed.
- **Deep link**: `app://awards/:kind` where `:kind` is the raw value of
  `AwardKind`.
- **Tab Bar**: visible.

---

## Component Schema

### Layout Structure (same across all 6 variants)

```
┌─────────────────────────────────────┐
│ StatusBar                            │
├─────────────────────────────────────┤
│ [Logo]  [🇻🇳 VN ▾] [🔍] [🔔•]        │ ← HomeHeader (shared)
├─────────────────────────────────────┤
│  Hệ thống ghi nhận và cảm ơn         │ ← mms_A_KV Kudos
│  [Kudo logo illustration]            │
├─────────────────────────────────────┤
│  [Sun* Annual Awards header]         │ ← mms_B_Highlight
│  [filter (year?) ▾]                  │
├─────────────────────────────────────┤
│  [======= Award artwork =======]     │ ← Picture-Award (kind-specific)
│                                      │
│  [Award title]                       │
│                                      │
│  [Long-form description — unique     │ ← kind-specific text
│   copy per AwardKind …]              │
│                                      │
│  ──────────                          │
│  [Stat label]    [Stat number]       │ ← kind-specific
│  ──────────                          │
│  [Stat label]    [Stat number]       │
├─────────────────────────────────────┤
│  Phong trào ghi nhận — Sun*Kudos     │ ← kudos block (identical across variants)
│  [Kudos banner]                      │
│  "ĐIỂM MỚI CỦA SAA 2025 …"           │
│  [ Chi tiết ]                        │
├─────────────────────────────────────┤
│ [SAA] [Awards] [Kudos] [Profile]    │ ← Tab Bar
└─────────────────────────────────────┘
```

### Component Hierarchy

```
AwardDetailScreen (SwiftUI View) — ViewModel injects `AwardKind`
├── HomeHeader (shared Organism)
├── BackgroundImage (Atom)
├── KVKudosBanner (Organism, static)                   # mms_A_KV Kudos
│   ├── TaglineLabel "Hệ thống ghi nhận và cảm ơn"
│   └── KudoLogoArtwork (Atom)
├── AwardHighlightBar (Organism)                       # mms_B_Highlight
│   ├── SectionHeader                                  # "Sun* Annual Awards …"
│   └── FilterControl (Molecule)                       # likely year selector
├── AwardBlock (Organism)                              # award frame
│   ├── AwardArtwork (Atom, kind-specific)             # Picture-Award variant
│   ├── AwardTitleBlock (Molecule, kind-specific)
│   │   ├── AwardTitle (Atom)
│   │   └── DescriptionParagraph (Atom)
│   ├── Divider
│   ├── AwardStatRow (Molecule, kind-specific)         # "title" + "number"
│   ├── Divider
│   └── AwardStatRow (Molecule, kind-specific)
├── KudosPromoBlock (Organism, static across variants) # kudos frame
│   ├── SectionHeader "Phong trào ghi nhận / Sun*Kudos"
│   ├── KudosBanner (Atom)
│   ├── KudosNote (Atom)
│   └── PrimaryButton "Chi tiết" → `[iOS] Sun*Kudos`
└── BottomTabBar (shared)
```

### Main Components

| Component | Type | Description | Reusable |
|-----------|------|-------------|----------|
| `HomeHeader` | Organism | Same shared header | ✅ (Home / Profile me / Profile other) |
| `KVKudosBanner` | Organism | Static brand banner, identical across all 6 awards | ✅ (reusable in any brand-adjacent screen) |
| `AwardArtwork` | Atom | Kind-specific | — (asset per variant) |
| `AwardBlock` | Organism | Parameterised layout — artwork + title + description + stat rows | **Yes — one view drives 6 variants** |
| `AwardStatRow` | Molecule | Label + big number | ✅ |
| `KudosPromoBlock` | Organism | Static block identical across variants | ✅ (candidate to share with other brand pages) |
| `BottomTabBar` | Organism | Shared | ✅ |

---

## Form Fields (If Applicable)

Not applicable.

---

## API Mapping

Backend: **Supabase**. Content is mostly static with optional dynamic
year-filter data.

### Content delivery options

- **Option A (recommended v1)**: award descriptions + stats bundled in
  the iOS app (`Localizable.xcstrings` + a static `AwardCatalog.swift`
  holding `AwardKind → AwardContentVM`). Zero-network read.
- **Option B (v-next)**: `awards` Supabase table (matches the endpoint
  already defined in home.md for the teaser list). Pulls
  `{ title_vi, title_en, description_vi, description_en,
  artwork_asset_key, stats: [{label, value}] }`.

Home's teaser list already fetches from `awards` (see SCREENFLOW API
summary). If Option B is adopted, reuse that same query and filter by
`kind`.

### On Screen Load / Resume

| Call | Method | Purpose | Response usage |
|------|--------|---------|----------------|
| `supabase.auth.getSession()` | SDK local | Auth guard | Redirect to Login if invalid |
| *(Option B only)* `supabase.from("awards").select("*").eq("kind", awardKind.rawValue).single()` | GET | Award content | Render header + description + stats |
| *(if filter is year-of-winners)* `supabase.from("award_winners").select("*").eq("award_kind", kind).eq("year", selectedYear)` | GET | Historical winners — stats rows | Populate stat row(s) |

### On User Action

| Action | Call | Method | Request | Response |
|--------|------|--------|---------|----------|
| Tap "Chi tiết" (Kudos block) | — | navigation | — | Push `[iOS] Sun*Kudos` |
| Change filter (year, TBC) | Refetch winners | GET | `{ year }` | Replace stat rows |
| Tap language chip / search / bell | — | navigation | — | Shared destinations |

### Error Handling

| Error | Source | UI action |
|-------|--------|-----------|
| Session expired | Guard | Redirect to Login |
| Award content fetch failed (Option B) | REST 5xx | Full-screen retry card (content is load-bearing) |
| Filter/winners fetch failed | REST | Inline retry below the stat section |

---

## State Management

### Local State (ViewModel — Principle III)

```swift
protocol AwardDetailViewModel {
    let awardKind: AwardKind                 // injected at construction

    // Inputs
    var viewAppeared: PublishRelay<Void> { get }
    var filterChanged: PublishRelay<AwardFilter> { get }   // e.g. .year(2024 | 2025 | .all)
    var kudosDetailsTapped: PublishRelay<Void> { get }

    // Outputs
    var content: Driver<AwardContentVM?> { get }           // title, description, artwork
    var stats: Driver<[AwardStatVM]> { get }               // may depend on filter
    var isLoading: Driver<Bool> { get }
    var errorMessage: Signal<String> { get }
    var navigate: Signal<AppRoute> { get }
}
```

For Option A, `content` is loaded synchronously from `AwardCatalog`;
only `stats` may require async + filter logic.

### Global State

| State | Store | R/W | Purpose |
|-------|-------|-----|---------|
| `AuthState` | `AuthStore` | R | Guard |
| `UnreadNotificationCount` | `NotificationStore` | R | Header bell dot |

No write to `TabRouter` — this screen is pushed above a tab (likely
`.saa` when coming from Home, or `.awards` from the Awards tab).

---

## UI States

### Loading State

- Option A: no loading for content; stat rows may show a skeleton
  until winners data arrives (if filter is dynamic).
- Option B: full-screen skeleton on initial fetch.

### Error State

- Content fetch fail (Option B) → full-screen retry card.
- Stats fetch fail → inline retry row beneath the divider.

### Success State

- All blocks populated; `Chi tiết` CTA enabled.

### Empty State

- Stats empty (e.g. no winners yet for the selected year) → friendly
  placeholder "Sắp công bố" / "To be announced".

---

## Accessibility (Principle II)

| Requirement | Implementation |
|-------------|----------------|
| Screen context | Announce `"\(award.title). \(award.description, 1 sentence)"` on appear |
| Award artwork | `.accessibilityLabel("Biểu tượng giải \(award.title)")` |
| Description | Full prose read naturally — reading order header → description → stats → kudos promo |
| Stat row | `.accessibilityLabel("\(label): \(number)")` |
| Kudos promo CTA | `.isButton` + hint `"Mở phong trào Sun*Kudos"` |
| Dynamic Type | Long description scales to AX5 with `lineLimit(nil)`; stat numbers use `fixedSize` |
| Touch targets | Filter ≥ 44 pt; CTA ≥ 44 pt; header icons via 44×44 wrappers |
| Localisation | VN + EN keys per `AwardKind` (title + description + stat labels) |

---

## Responsive Behavior

| Device class | Layout |
|--------------|--------|
| iPhone portrait | As designed |
| iPhone landscape | Content scrolls; artwork capped at 40% viewport height |
| iPad | Max width 600 pt, centered |
| AX3+ | Stat rows stack vertically; artwork retains intrinsic size |

---

## Analytics Events (Optional)

| Event | Trigger | Properties |
|-------|---------|------------|
| `award_detail.viewed` | On appear | `{ kind, source }` |
| `award_detail.filter_changed` | Filter change | `{ kind, from, to }` |
| `award_detail.kudos_cta_tap` | CTA tap | `{ kind }` |

Principle V: log only `kind`/counts; never log winner names if surfaced
in stats.

---

## Design Tokens

| Token | Usage |
|-------|-------|
| `Color("TextPrimary")` | Title |
| `Color("TextSecondary")` | Description |
| `Color("BrandPrimary")` | CTA |
| `Color("StatHighlight")` | Stat number |
| Font: `.title` → award title, `.body` → description, `.largeTitle` → stat number, `.headline` → CTA |
| Asset per kind: `Image("award_\(kind.rawValue)")` — export via `/momorph.specs` |

---

## Implementation Notes

### Clean Architecture touch-points (Principle I)

- **Presentation**:
  `Presentation/Awards/Views/AwardDetailView.swift`,
  `Presentation/Awards/ViewModels/AwardDetailViewModel.swift`,
  `Presentation/Awards/ViewModels/AwardDetailStateAdapter.swift`,
  `Presentation/Awards/Components/AwardBlockView.swift`,
  `Presentation/Awards/Components/AwardStatRowView.swift`,
  `Presentation/Shared/Components/KVKudosBannerView.swift` (shared),
  `Presentation/Shared/Components/KudosPromoBlockView.swift` (shared).
- **Domain**:
  `Domain/Entities/AwardKind.swift` (enum, 6 cases),
  `Domain/Entities/AwardContent.swift` (title + description + artworkKey + stats),
  *(Option B)* `Domain/UseCases/FetchAwardContentUseCase.swift`,
  *(Option B)* `Domain/UseCases/FetchAwardWinnersUseCase.swift` (filterable),
  *(Option A)* `Core/Catalog/AwardCatalog.swift` (static dictionary).
- **Data**:
  *(Option B)* `Data/Repositories/AwardRepositoryImpl.swift` — reuses
  the same repo introduced for Home teaser.

### Key Domain model

```swift
enum AwardKind: String, CaseIterable, Codable {
    case mvp
    case bestManager
    case signatureCreator            // "Signature 2025 — Creator"
    case topProject
    case topProjectLeader
    case topTalent
}

struct AwardContent {
    let kind: AwardKind
    let title: LocalizedStringKey              // "award.\(kind).title"
    let description: LocalizedStringKey        // "award.\(kind).description"
    let artworkAsset: String                   // "award_\(kind.rawValue)"
    let stats: [AwardStat]                     // up to 2, order preserved
}

struct AwardStat {
    let labelKey: LocalizedStringKey
    let value: String                          // "5", "2024", etc.
}
```

### Reactive model (Principle III)

- `viewAppeared` → `flatMap { repo.fetchContent(kind) }` (or `just` for
  Option A) → `contentRelay`.
- `filterChanged` → `flatMapLatest { year in repo.fetchWinners(kind, year).asObservable() }` → `statsRelay`.
- CTA taps merged into one `Signal<AppRoute>`.

### Security (Principle V)

- Option B: `awards` table policy `SELECT using (auth.uid() is not null)`.
- No service-role access from client.
- Logs limit to `kind` identifiers.

### Edge cases

- Unknown `kind` in deep link (e.g. `app://awards/foo`) → route to
  `[iOS] Not Found` with `source: .deeplink`.
- Content missing for a variant (Option B, DB inconsistency) → show the
  full-screen retry card; log a warning with the `kind` (no PII).
- Device back-tap from deep-link entry (no stack parent) → fall through
  to Home.

---

## Analysis Metadata

| Property | Value |
|----------|-------|
| Analyzed By | `/momorph.screenflow` |
| Analysis Date | 2026-04-24 |
| Source | `get_overview` (depth 4) on 3 frames: `b2BuS8HYIt` (MVP), `FQoJZLkG_d` (Top project), `c-QM3_zjkG` (Top talent). Structural parity confirmed. The remaining 3 (`7y195PPTxQ`, `O98TwiHaJe`, `QQvsfK3yaK`) inherit the same layout by analogy; content will be captured during `/momorph.specs`. |
| Needs Deep Analysis | Filter semantics (year selector?) + stat-row meaning (prize count / budget / winners count) — medium |
| Confidence Score | High for structure; Medium for filter + stat-row semantics |

### Next Steps

- [ ] Capture exact VN + EN copy for the 3 un-inspected variants
      (`bestManager`, `signatureCreator`, `topProjectLeader`) during
      `/momorph.specs` — add to `AwardCatalog` (Option A) or seed into
      `awards` table (Option B).
- [ ] Confirm filter semantics and stat-row meaning with design
      (year-of-winners filter vs. something else) during `/momorph.specs`.
- [ ] Export per-kind artwork assets.
- [ ] Lock in `AwardKind` enum + `.xcconfig` route parameter mapping.
- [ ] Decide Option A vs. Option B (recommend A for v1; revisit if
      content stability is a concern).
