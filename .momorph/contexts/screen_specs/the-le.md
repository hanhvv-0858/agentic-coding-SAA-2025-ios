# Screen: [iOS] Thể lệ

## Screen Info

| Property | Value |
|----------|-------|
| **Figma Frame ID** | `zIuFaHAid4` (node `6885:10860`) |
| **Figma Link** | https://momorph.ai/files/9ypp4enmFmdK3YAFJLIu6C/screens/zIuFaHAid4 |
| **Screen Group** | Static content (rules) |
| **Platform** | iOS (SwiftUI) |
| **Status** | discovered |
| **Discovered At** | 2026-04-24 |
| **Last Updated** | 2026-04-24 |

---

## Description

`[iOS] Thể lệ` ("Rules") is a **static long-form content screen** that
explains how the SAA 2025 Sun\*Kudos programme works. It presents:

1. A **cover image** at the top.
2. **Rule for receivers** — "NGƯỜI NHẬN KUDOS: HUY HIỆU HERO CHO NHỮNG
   ẢNH HƯỞNG TÍCH CỰC". Hero-level taxonomy with visual badges + copy:
   - **New Hero** — "Hành trình lan tỏa điều tốt đẹp bắt đầu…"
   - **Rising Hero** — (same start-of-journey copy)
   - **Super Hero** — "Bạn đã trở thành biểu tượng được tin tưởng…"
   - **Legend Hero** — (top tier, same "biểu tượng" copy)
3. **Rule for senders** — "NGƯỜI GỬI KUDOS: SƯU TẬP TRỌN BỘ 6 ICON…":
   - **Mechanic**: every 5 ❤ received on your sent Kudos → 1 Secret Box.
   - Each Secret Box can reveal one of **6 exclusive SAA icons**
     (REVIVAL / TOUCH OF LIGHT / STAY GOLD / FLOW TO HORIZON /
     BEYOND THE BOUNDARY / ROOT FUTHER).
   - **Collecting all 6** → "phần quà bí ẩn" (mystery prize).
4. **Kudos Quốc Dân** — top 5 kudos with the most ❤ on the whole
   Sun\* system receive the special prize **"Root Further"**.
5. Actions row: **Đóng** (dismiss) + primary CTA **Viết Kudos**.

This screen **confirms three key taxonomies** surfaced earlier and
introduces one new concept:

- ✅ **4 Hero tiers**: New → Rising → Super → Legend (seen in
  profile-me.md, now labelled with authoritative descriptions).
- ✅ **6-badge set**: REVIVAL · TOUCH OF LIGHT · STAY GOLD · FLOW TO
  HORIZON · BEYOND THE BOUNDARY · ROOT FUTHER (matches profile-other.md).
- ✅ **Secret Box mechanic**: 5 hearts on your kudos = 1 Secret Box.
- ✨ **New: "Kudos Quốc Dân"** — top-5 hearted kudos → special prize
  "Root Further".

---

## Navigation Analysis

### Incoming Navigations (From)

| Source | Trigger | Condition |
|--------|---------|-----------|
| `[iOS] Home` | Tap `ABOUT AWARD` (high confidence) or a dedicated "Thể lệ" link in any menu | Design shows `ABOUT AWARD` as a hero CTA — this spec assumes that CTA lands here rather than scrolling to the Awards teaser as home.md currently notes; **revisit home.md** |
| `[iOS] Sun*Kudos` | Likely a "Thể lệ" shortcut inside the Kudos feed | Medium — to confirm during Wave 5 (Sun*Kudos cluster) |
| Deep link | `app://rules` | Any time |

### Outgoing Navigations (To)

| Target | Trigger Element | Node ID | Confidence | Notes |
|--------|-----------------|---------|------------|-------|
| (previous screen) | Back Icon | `6885:10879` | High | Standard `NavigationStack` pop |
| (previous screen) | Button "Đóng" | `6885:10947` | High | Same behaviour as Back — dual dismissal affordance |
| `[iOS] Sun*Kudos_Gửi lời chúc Kudos` (`PV7jBVZU1N`) | Button "Viết Kudos" | `6885:10948` | High | Opens compose with no recipient pre-filled |

### Navigation Rules

- **Auth required**: **Yes** — the CTA leads into an authenticated
  action. If the rules happen to be read by an unauthenticated user
  (unlikely because every route to here is behind auth), route the
  CTA to `[iOS] Login` with a replay target of `Viết Kudos`.
- **Back behavior**: pop. Tab Bar state is preserved (pushed above tab).
- **Deep link**: `app://rules` supported.

### Design ambiguity — Home `ABOUT AWARD` destination

In [home.md](home.md), `ABOUT AWARD` was noted as a **scroll-to-section
anchor** within Home. After reading Thể lệ, the more plausible
interpretation is:

- `ABOUT AWARD` → **push `[iOS] Thể lệ`** (this screen — the full rules).
- `ABOUT KUDOS` → still a scroll-to-section anchor for the KudosSection.

Proposed: update home.md during Wave 5 or on request to reflect this.
The current analysis for Thể lệ assumes `ABOUT AWARD` → here.

---

## Component Schema

### Layout Structure

```
┌─────────────────────────────────────┐
│ StatusBar                            │
├─────────────────────────────────────┤
│ [←]    Thể lệ                        │ ← TopNavigation (with title)
├─────────────────────────────────────┤
│ [========== Cover ===========]       │ ← mms_3_Cover
├─────────────────────────────────────┤
│  Thể lệ                              │ ← section title
│                                      │
│  NGƯỜI NHẬN KUDOS:                   │ ← mms_4.1 header
│  HUY HIỆU HERO CHO NHỮNG ẢNH HƯỞNG   │
│  TÍCH CỰC                            │
│  Dựa trên số lượng đồng đội …        │
│  ────────────                        │
│                                      │
│  [🎖 New Hero]                       │ ← mms_4.2 Hero tiers (×4)
│  Hành trình lan tỏa…                 │
│                                      │
│  [🎖 Rising Hero]                    │
│  …                                   │
│                                      │
│  [🎖 Super Hero]                     │
│  …                                   │
│                                      │
│  [🎖 Legend Hero]                    │
│  …                                   │
│  ────────────                        │
│                                      │
│  NGƯỜI GỬI KUDOS: SƯU TẬP TRỌN BỘ    │ ← mms_4.3 sender rule
│  6 ICON…                             │
│  Mỗi lời Kudos bạn gửi…              │
│  [🎖][🎖][🎖]   [🎖][🎖][🎖]          │   6 icons (2 rows of 3)
│  Những Sunner thu thập trọn bộ…      │
│  ────────────                        │
│                                      │
│  KUDOS QUỐC DÂN                      │ ← mms_4.4
│  5 Kudos nhận về nhiều ❤ nhất…       │
│                                      │
├─────────────────────────────────────┤
│   [ Đóng ]     [ Viết Kudos ]        │ ← mms_4.5 actions
└─────────────────────────────────────┘
```

### Component Hierarchy

```
TheLeScreen (SwiftUI View)
├── TopNavigation (shared)                         # 6885:10864
│   └── Title "Thể lệ"
├── BackgroundImage (Atom)                         # bg
├── CoverImage (Atom)                              # mms_3_Cover (6885:10882)
├── ScrollableRulesContent (Organism)              # mms_4
│   ├── SectionHeader (Molecule)                   # mms_4.1
│   │   ├── "Thể lệ"
│   │   ├── ReceiverRuleTitle (Atom)
│   │   └── ReceiverRuleDescription (Atom)
│   ├── Divider
│   ├── HeroTierList (Organism)                    # mms_4.2
│   │   └── HeroTierRow ×4 (Molecule)
│   │       ├── LevelBadge (shared Atom/Molecule)  # variants: New/Rising/Super/Legend
│   │       └── TierDescription (Atom)
│   ├── Divider
│   ├── SenderRuleBlock (Organism)                 # mms_4.3
│   │   ├── SenderRuleTitle (Atom)
│   │   ├── SenderMechanicParagraph (Atom)
│   │   ├── BadgeShowcaseGrid (Molecule)           # same 6 badges as Profile người khác
│   │   │   └── BadgeShowcaseCell ×6
│   │   └── SenderRewardNote (Atom)
│   ├── Divider
│   └── KudosQuocDanBlock (Organism)               # mms_4.4
│       ├── Title "KUDOS QUỐC DÂN"
│       └── Description
└── ActionsBar (Organism, pinned to bottom)        # mms_4.5
    ├── SecondaryButton "Đóng"                     # 6885:10947 → pop
    └── PrimaryButton "Viết Kudos"                 # 6885:10948 → write-kudo route
```

### Main Components

| Component | Type | Node ID | Description | Reusable |
|-----------|------|---------|-------------|----------|
| `TopNavigation` | Organism | `6885:10864` | Shared app-wide | ✅ |
| `LevelBadge` (×4 tiers) | Molecule | `mm_media_Danh hiệu New/Rising/Super/Legend Hero` (components `6885:8946 / 8950 / 8953 / 8957`) | Same shared component as Profile — tier selector maps to the right artwork | ✅ |
| `BadgeShowcaseCell` | Molecule | `6885:10935-10941` (`mm_media_Huy hiệu` component instances) | Same reusable badge artwork as Profile người khác's named grid, without labels in this context | ✅ |
| `ActionsBar` | Organism | `6885:10946` | Two-button row fixed at bottom | Yes (pattern reused in other rule-like screens e.g. Community Standards) |
| `CoverImage` | Atom | `6885:10882` | Static hero cover — asset provided by design | No |

---

## Form Fields (If Applicable)

Not applicable — this is static content.

---

## API Mapping

**No API calls.** All content is static for v1. Two delivery options:

### Option A (recommended v1): bundle in the app

- Localised strings in `Localizable.xcstrings`.
- Hero tier descriptions, badge names, Kudos Quốc Dân copy all stored
  as keys.
- Cover image ships as an asset.

**Pros**: zero network dependency; reads instantly; no RLS to worry
about.
**Cons**: requires an app release to update copy.

### Option B (v-next if needed): fetch from a Supabase `rules` table

- `supabase.from("rules").select("*").eq("key", "the_le_saa2025").single()`
- Returns a JSON blob of ordered sections.
- Requires caching + a stale-while-revalidate strategy.

**Recommendation**: ship v1 with Option A. Revisit if product signals
the content will change mid-event.

### On User Action

| Action | Call | Method | Request | Response |
|--------|------|--------|---------|----------|
| Tap Back / Đóng | — | navigation | — | Pop |
| Tap "Viết Kudos" | — | navigation | — | Push `[iOS] Sun*Kudos_Gửi lời chúc Kudos` (no prefill) |

---

## State Management

### Local State (ViewModel — Principle III)

The screen is effectively static but keeps Rx parity:

```swift
protocol TheLeViewModel {
    // Inputs
    var closeTapped: PublishRelay<Void> { get }          // Back or Đóng
    var writeKudoTapped: PublishRelay<Void> { get }

    // Outputs
    var navigate: Signal<AppRoute> { get }               // .pop | .sunKudos(.writeKudo)
}
```

No data-fetch state, no loading/error states in v1 (Option A).

### Global State

| State | Store | R/W | Purpose |
|-------|-------|-----|---------|
| `AuthState` | `AuthStore` | R | Defensive guard before routing to the compose screen |

---

## UI States

### Loading State

N/A in v1 (Option A). If we later switch to Option B, add skeletons for
the four content blocks.

### Error State

N/A in v1.

### Success State

All content rendered; ActionsBar sticks to the bottom safe-area.

### Empty State

N/A.

---

## Accessibility (Principle II)

| Requirement | Implementation |
|-------------|----------------|
| Screen title | Announced as `"Thể lệ"` via `TopNavigation` |
| Scroll content | Group `ScrollableRulesContent` with `.accessibilityElement(children: .contain)`; reading order: ReceiverRule → HeroTiers → SenderRule → KudosQuocDan |
| HeroTierRow | Composite label: `"\(tier), \(description)"` — e.g. `"New Hero, Hành trình lan tỏa điều tốt đẹp bắt đầu — những lời cảm ơn và ghi nhận đầu tiên đã tìm đến bạn."` |
| Badges | Each cell announces its name (REVIVAL, TOUCH OF LIGHT, …) + optional description |
| ActionsBar | Secondary "Đóng" = `.isButton` + hint "Đóng màn thể lệ"; Primary "Viết Kudos" = `.isButton` + hint "Viết lời ghi nhận mới" |
| Dynamic Type | All prose wraps to AX5; 2×3 badge grid collapses to 6×1 at AX3+ |
| Touch targets | Both action buttons ≥ 44 pt |
| Reduced motion | No animation on scroll anchors |
| Localisation | Every string via `Localizable.xcstrings` (VN + EN) |

---

## Responsive Behavior

| Device class | Layout |
|--------------|--------|
| iPhone portrait | As designed |
| iPhone landscape | Cover shrinks to ~30% viewport height; content scrolls; ActionsBar pinned to bottom safe-area |
| iPad | Max width 600 pt, centered; badge grid stays 2×3 |

---

## Analytics Events (Optional)

| Event | Trigger | Properties |
|-------|---------|------------|
| `rules.viewed` | On appear | `{ source }` — `home.about_award / sun_kudos.link / deeplink` |
| `rules.close` | Back / Đóng | `{ source }` |
| `rules.write_kudo_tap` | CTA | `{ source }` |

---

## Design Tokens

| Token | Usage |
|-------|-------|
| `Color("TextPrimary")` | Body copy |
| `Color("TextSecondary")` | Section-level dividers / notes |
| `Color("BrandPrimary")` | Primary CTA bg |
| `Color("BrandSecondary")` | Secondary CTA bg ("Đóng") |
| Font: `.title2` → section titles, `.title3` → subsection titles (NGƯỜI NHẬN / NGƯỜI GỬI / KUDOS QUỐC DÂN), `.body` → prose, `.headline` → button labels |
| Asset: `Image("the_le_cover")` (to export at `/momorph.specs`), `Image("badge_\(kind.rawValue)")` per the 6 kinds |

---

## Implementation Notes

### Clean Architecture touch-points (Principle I)

- **Presentation**: `Presentation/Rules/Views/TheLeView.swift`,
  `Presentation/Rules/ViewModels/TheLeViewModel.swift`,
  `Presentation/Rules/Components/HeroTierRowView.swift`,
  `Presentation/Rules/Components/BadgeShowcaseGridView.swift`,
  `Presentation/Rules/Components/ActionsBarView.swift`.
- **Shared reuse**:
  - `Presentation/Shared/Components/LevelBadgeView.swift` (same
    component as Profile).
  - `Presentation/Shared/Navigation/TopNavigation.swift`.
- **Domain / Data**: **none**. All content is static. If Option B is
  ever adopted, introduce `FetchRulesUseCase` + `RulesRepository`.

### Reactive model (Principle III)

- Minimal: `Signal<AppRoute>` merged from `closeTapped` and
  `writeKudoTapped`, observed by `AppRouter`.

### Security (Principle V)

- Content is static and public — no RLS.
- If we switch to Option B, the `rules` table should allow `SELECT` to
  any authenticated user; mutating rows must be admin-only.

### Taxonomy & constants

Lock these values into Domain models for re-use:

```swift
enum HeroTier: String, CaseIterable, Codable {
    case newHero, risingHero, superHero, legendHero

    /// VN/EN display + description key live in Localizable.xcstrings
    var displayKey: LocalizedStringKey { "heroTier.\(rawValue).display" }
    var descriptionKey: LocalizedStringKey { "heroTier.\(rawValue).description" }
}

enum BadgeKind: String, CaseIterable, Codable {
    case revival, touchOfLight, stayGold, flowToHorizon, beyondTheBoundary, rootFurther

    var displayKey: LocalizedStringKey { "badge.\(rawValue).display" }
}

/// Confirmed mechanic from the rules copy
enum Mechanic {
    static let heartsPerSecretBox = 5      // 5 ❤ → 1 Secret Box
    static let totalBadgesForMysteryPrize = 6
    static let kudosQuocDanTopN = 5
}
```

### Edge cases

- User navigates here while offline — Option A content reads
  instantly; no error. Option B would require a cached fallback.
- User taps "Viết Kudos" but Supabase auth has expired → `AppRouter`
  detects invalid session and reroutes to Login with a replay target.
- Typo in badge asset name (`ROOT FUTHER` vs. `FURTHER`) — handled
  per profile-other.md: display string preserved, identifier uses
  `rootFurther`.

---

## Analysis Metadata

| Property | Value |
|----------|-------|
| Analyzed By | `/momorph.screenflow` |
| Analysis Date | 2026-04-24 |
| Source | `get_overview` on `zIuFaHAid4` (depth 5) |
| Needs Deep Analysis | No |
| Confidence Score | High for structure and content; Medium for entry-point mapping (Home `ABOUT AWARD` assumption) |

### Next Steps

- [ ] Confirm Home's `ABOUT AWARD` destination: scroll anchor (current
      home.md) vs. push to Thể lệ (this spec's assumption). Update
      home.md accordingly.
- [ ] Lock in the **6-badge enum** (including `rootFurther` identifier
      with the design-provided display string `ROOT FUTHER`).
- [ ] Lock in the **4-tier Hero enum** and descriptions in
      `Localizable.xcstrings`.
- [ ] Lock in mechanic constants: `heartsPerSecretBox = 5`,
      `totalBadgesForMysteryPrize = 6`, `kudosQuocDanTopN = 5`.
- [ ] Export the cover image asset during `/momorph.specs`.
- [ ] Add an "About / Rules" entry point in the Kudos tab (likely on
      `[iOS] Sun*Kudos`) — confirm during Wave 5.
