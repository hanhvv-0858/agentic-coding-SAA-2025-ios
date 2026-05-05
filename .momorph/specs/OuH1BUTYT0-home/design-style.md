# Design Style — `[iOS] Home` (`OuH1BUTYT0`)

**Source**: Figma file `9ypp4enmFmdK3YAFJLIu6C`, frame `OuH1BUTYT0`
(node `6885:8978`).
**Canvas**: 375 × 1942 pt (iPhone X-class baseline; 1 pt = 1 px).
Note this height is the *full Home* — content scrolls; only the
top ~812 pt is visible at rest.

**Authoring discipline** (per [plan.md](plan.md) §Visual Parity Strategy):

- This file is **incrementally authored**. Each US-phase Visual-Parity
  task (T103–T110) appends its own section. `T103` (US1) seeds the
  global tokens + Header + Hero + Theme-note. T104 (US2) appends
  Awards + Kudos sections, etc.
- Tokens come from **live Figma queries** at task time
  (`mcp__momorph__list_frame_styles` / `query_section` / `get_node`).
  When the MCP CSS approximation disagrees with the Figma color
  picker, **trust the picker** (lesson from the M1 Login gradient).

---

## 0 · Parity Baseline (drift freeze contract)

Per [plan.md](plan.md) §Visual Parity Strategy "Figma drift freeze
gate": every parity task after T103 calls `mcp__momorph__get_frame`
and compares the screen `revision` to this baseline. If the revision
has changed, the task **STOPS** and escalates to Designer + PM —
either the change reverts, or this baseline is bumped and every
previously-shipped US phase re-verifies.

| Field         | Value                                          | Captured at | Captured by |
|---------------|------------------------------------------------|-------------|-------------|
| Frame         | `[iOS] Home` (`OuH1BUTYT0`, node `6885:8978`)  | T103a       | Hanh (impl) |
| Revision hash | `3c9059f3da88539320cb62e39aefcf38`             | 2026-04-27  | T103a       |
| Frame updated | `2026-04-06T05:11:48.015356+00:00`             | 2026-04-27  | T103a       |
| Status        | `design`                                       | 2026-04-27  | T103a       |

**Drift-check command** for T104–T110:

```
mcp__momorph__get_frame screenId=OuH1BUTYT0
# Compare frame.revision to the Revision hash row above.
# Equal → proceed; different → STOP + escalate.
```

The MCP `get_node` does not currently expose a per-node `lastModified`
field — frame-level revision is the single drift signal. If a future
MCP version exposes per-node timestamps, augment this table.

---

## 1 · Color tokens

All values verbatim from Figma `styles.background` / `styles.fill` /
`styles.backgroundColor`. Tokens already shipped by M1 are flagged
`(M1)` so the implementer reuses the existing `Assets.xcassets` Color
Set rather than creating a duplicate.

| Token (xcassets name)        | Hex        | Alpha | Used by (US1)                                                |
|------------------------------|------------|-------|--------------------------------------------------------------|
| `BrandOnCream` (M1)          | `#00101A`  | 1.00  | Screen background; ABOUT AWARD label                         |
| `BrandCream`   (M1)          | `#FFEA9E`  | 1.00  | ABOUT AWARD button background; date/venue emphasised values  |
| `DropdownBorder` (M1)        | `#998C5F`  | 1.00  | ABOUT KUDOS button border                                    |
| `ChipBackground` (M1)        | `#000000`  | 0.30  | Header language chip soft tint (M1 deviation — Figma chip is transparent; M1 added 30% black for keyvisual robustness, kept for Home consistency) |
| (computed)                   | `#FFEA9E`  | 0.10  | ABOUT KUDOS button background fill                           |
| (system) `.white`            | `#FFFFFF`  | 1.00  | Body text (white labels), countdown digits, "Coming soon", livestream copy |

**Header gradient overlay** (`mms_1_header`, full-width 375 × 104 pt
anchored to top, layered above keyvisual). The MCP `list_frame_styles`
returned a 7-stop CSS approximation:

```
linear-gradient(180deg,
  #00101A         0%,
  rgba(0,16,26,0.30)  76.44%,
  rgba(0,16,26,0.20)  84.62%,
  rgba(0,16,26,0.15)  88.7%,
  rgba(0,16,26,0.10)  92.79%,
  rgba(0,16,26,0.05)  96.39%,
  rgba(0,16,26,0.00) 100%
)
```

**However** — the M1 Login gradient lesson is that MCP CSS dumps are
curve-fits, not canonical. M1 Login uses a **4-stop** gradient
(`1.00 / 0.90 / 0.60 / 0.00` evenly distributed). For Home, treat the
M1 4-stop as the canonical pattern and **only deviate after opening
Figma's color picker on this gradient and confirming the actual stop
list**. Implementation re-uses the M1 4-stop until the picker is
checked at T103b (final visual parity). Recorded as a known
deviation §6 #1.

The frame-level `opacity: 0.9` on `mms_1_header` applies on top of the
gradient — the header band is 90% opaque overall so the keyvisual
shows through faintly at the very top.

---

## 2 · Typography

Design uses **Montserrat** (300 / 400 / 500). iOS does not ship
Montserrat. M1 substitution stands: **SF Pro (system font)** at the
same sizes / weights. Letter-spacing units are pt (1 px = 1 pt at
baseline).

| Role                         | Family     | Size   | Weight | Line-h | Letter-sp | Color           | Align  |
|------------------------------|------------|--------|--------|--------|-----------|-----------------|--------|
| Body labels (small)          | Montserrat | 14 pt  | 300    | 20 pt  | +0.25     | white           | LEFT   |
| Livestream copy              | Montserrat | 14 pt  | 400    | 20 pt  | +0.25     | white           | LEFT   |
| Emphasised values (date/venue) | Montserrat | 18 pt | 400    | 24 pt  | +0.50     | `BrandCream`    | LEFT   |
| Button label (ABOUT, chip)   | Montserrat | 14 pt  | 500    | 20 pt  | 0         | per button bg   | CENTER |
| Theme paragraph              | Montserrat | 14 pt  | 300    | 20 pt  | +0.25     | white           | LEFT   |
| "Coming soon" label          | Montserrat | 14 pt  | 300    | 20 pt  | +0.25     | white           | LEFT   |

> Countdown digit cell typography (the big numbers) is captured at
> US1's countdown component spec in §3.4 — depth-4 children of
> `6885:8989 / 8998 / 9007` were not extracted in the first query
> sweep; the implementer fetches them via `query_section` of the
> three cells when building `CountdownTimerView` and adds the row
> to this table at that time.

---

## 3 · US1 component specs

### 3.1 Frame & background

- Screen: **375 × 1942 pt total** (scrolling). Visible band at rest =
  812 pt. Background fallback `BrandOnCream` (`#00101A`).
- Keyvisual `mm_media_bg` group: 1114 × 812 pt, x = 601 (yes — the
  art extends past the screen's right edge for parallax safety).
  Anchor inside the screen at startX=601, startY=0 → endX=375,
  endY=812 (clipped to screen). The visible portion is the right
  half of the keyvisual.

### 3.2 Header (`mms_1_header` — `6885:9057`)

Anchored to top. 375 × 104 pt, instance opacity 0.9, gradient bg per §1.

| Element              | Position (x, y → x', y') | Size   | Notes                              |
|----------------------|--------------------------|--------|------------------------------------|
| Status bar           | 0, 0   → 375, 44         | 375×44 | system                             |
| Brand logo           | 20, 52 → 68, 96          | 48×44  | 8 pt below status bar; left edge   |
| Actions cluster      | 233, 64 → 355, 96        | 122×32 | Right-aligned flex row, gap 10 pt  |
| └─ Language chip     | 197, 64 → 287, 96        | 90×32  | Padding `4 0 4 8`, radius 4 pt     |
| └─ Search icon       | 297, 68 → 321, 92        | 24×24  | gap 10 pt to chip                  |
| └─ Bell icon         | 331, 68 → 355, 92        | 24×24  | gap 10 pt to search                |

**Δ vs M1 Login header**: Login had ONE chip at 265,64 → 355,96
(right-edge anchored). Home has THREE icons (chip + search + bell).
The chip slides LEFT to 197 to make room for search + bell on the
right. Logo position is identical (component reused).

### 3.3 Language chip (`I6885:9057;88:1829` — re-used from M1)

Same component instance as Login's chip. Refer to M1's
[design-style.md §3.3](../8HGlvYGJWq-authentication/design-style.md)
for chip internals (flag icon 24×24 + chevron 24×24, gap 8, radius 4).

Background on Home: same as Login = `ChipBackground` (M1 deviation =
30% black tint over Figma's transparent design). The keyvisual
behind the chip can be bright; the tint preserves contrast.

### 3.4 Bell with unread dot (`I6885:9057;88:1830`)

- Bell instance: 24 × 24 pt at (331, 68).
- Unread dot child `I6885:9057;88:1830;72:1627`: 8 × 8 pt circle
  (border-radius 100 pt = pill ≈ circle), positioned at (346, 69).
  → top-right corner of the bell, offset 1 pt down + 1 pt left from
  the bell's top-right.
- Dot fill color: not surfaced by the depth-3 query — fetch with
  `query_section` of the dot node when implementing US3 visual
  parity (T105). For M2 PR-M2.2, use `Color.red` as a known
  placeholder; T105 verifies the actual hex.

### 3.5 Hero (`mms_2_content` — `6885:8983`)

Frame: 335 × 453 pt at (20, 144), vertical column flex, gap 32 pt.

```
y = 144 ── hero start
y = 144 → 253 ── ROOT FURTHER wordmark (247 × 109 pt at x=20)
y = 285 → 525 ── countdown + event-info group (335 × 240 pt, gap 24 pt)
   y = 285 → 397 ── countdown block (335 × 112 pt, gap 8 pt)
      y = 285 → 305 ── "Coming soon" label (335 × 20 pt)
      y = 313 → 397 ── countdown digits row (268 × 84 pt, gap 16 pt)
         (20–92)  days   72×84
         (108–180) hours 72×84
         (196–288) min   92×84
   y = 421 → 525 ── event info (3 rows, 335 × 104 pt, gap 8 pt)
      y = 421 → 445 ── "Thời gian: " + "26/12/2025"      (gap 8)
      y = 453 → 477 ── "Địa điểm:"   + "Âu Cơ Art Center" (gap 8)
      y = 485 → 525 ── livestream paragraph (335 × 40 pt, 2 lines)
y = 557 → 597 ── ABOUT buttons row (335 × 40 pt, gap 16 pt)
   (20–180)  ABOUT AWARD  160 × 40, padding 12, radius 4, bg BrandCream, label BrandOnCream + 24px icon
   (196–355) ABOUT KUDOS  159 × 40, padding 10, radius 4, bg BrandCream@10%, border 1px DropdownBorder, label white + 24px icon
```

Hero logo `HeroLogo` (M1 asset) — same component instance as Login.
247 × 109 pt is identical to Login's hero. Reuse `Assets.xcassets/HeroLogo.imageset`.

### 3.6 Theme paragraph (`mms_3_note` — `6885:9028`)

Frame: 335 × 240 pt at (20, 637). Single TEXT child node `6885:9029`,
333 × 240 pt. Vertical row alignment center, but the only child is a
multi-line text block so visually it reads as a left-aligned paragraph.

Typography: **Montserrat 14 pt / 300 / 20 pt line-height / +0.25
letter-spacing / white**. Same as the body-label role in §2.

**Real VN copy from Figma** (replaces the M2 placeholder `home.theme.note`):

> Không đơn thuần là một cái tên, "Root Further" chính là tinh thần
> mà mỗi người Sun\* đang hướng tới: luôn nhìn nhận sâu sắc trong
> mọi bối cảnh và không ngừng sáng tạo, mở rộng bản thân để vượt
> qua những giới hạn mà chính mình đã từng đặt ra. Mượn hình ảnh
> ẩn dụ của lý thuyết phối màu, chỉ từ ba màu cơ bản: đỏ, vàng và
> lam, sức sáng tạo vô tận của mỗi cá nhân có thể tạo ra số lượng
> màu sắc gần như vô hạn, với mỗi gam màu đều đại diện cho sự bứt
> phá và sáng tạo không giới hạn.

Figma frame contains VN only — EN is **not in scope of M2**. The
xcstrings entry for `home.theme.note` should ship the VN string in
both `vi` and `en` slots (with `state: needs_review` on `en`) until
the EN copy lands from Content team.

### 3.7 Vertical anchor map (full Home, 375 pt baseline)

US1 anchors only (US2–US8 anchors will be appended by their parity
tasks):

```
y =    0 ─── status bar top
y =   44 ─── status bar bottom
y =   52 ─── brand logo top         (gap from status bar = 8)
y =   64 ─── chip / search / bell top (gap from status bar = 20)
y =   96 ─── header content end + cluster bottom
y =  104 ─── header frame bottom
y =  144 ─── hero start (gap from header = 40)
y =  253 ─── hero logo bottom
y =  285 ─── countdown + event info group top (gap from hero logo = 32)
y =  305 ─── "Coming soon" bottom
y =  313 ─── countdown digits row top (gap = 8)
y =  397 ─── countdown digits row bottom
y =  421 ─── event info row 1 top (gap = 24)
y =  525 ─── event info bottom
y =  557 ─── ABOUT buttons row top (gap from event info = 32)
y =  597 ─── hero frame bottom
y =  637 ─── theme paragraph top (gap from hero = 40)
y =  877 ─── theme paragraph bottom
```

(Awards / Kudos / FAB / TabBar anchors land in T104–T109.)

On notched / Dynamic-Island devices, anchor `mms_1_header` to the
safe-area top with the same 8 pt logo / 20 pt cluster insets — let
the bottom Spacer absorb device-height delta (matches M1 Login
pattern in `LoginView.swift`).

---

## 4 · Asset inventory (US1 only)

| xcassets name        | Source                  | Dimensions       | Figma node                    | Status (M2 PR-M2.2) |
|----------------------|-------------------------|------------------|-------------------------------|---------------------|
| `KeyvisualBackground` (M1) | PNG (raster)      | 881 × 723        | `6885:8980`                   | ✅ reuse from M1    |
| `BrandLogoSmall` (M1) | PNG                    | 48 × 44 (display)| `I6885:9057;88:1827;65:1760`  | ✅ reuse from M1    |
| `HeroLogo` (M1)      | PNG                     | 247 × 109 (display)| `I6885:8984;65:1590`        | ✅ reuse from M1    |
| (search icon)        | Figma component `6885:8147` | 24 × 24      | `I6885:9057;88:1869`          | NEW — fetch at T028 |
| (bell icon)          | Figma component `6885:8136` | 24 × 24      | `I6885:9057;88:1830`          | NEW — fetch at T028 |
| (down chevron)       | Figma component `6885:7645` | 24 × 24      | (chip child)                  | ✅ reuse from M1's chip |
| (VN flag)            | (emoji `🇻🇳`)          | system          | (chip child)                  | ✅ reuse from M1's chip |

Search and bell icons can ship as SF Symbols (`magnifyingglass` /
`bell`) for the first PR-M2.2 build if Figma export is non-trivial,
documented as a deviation in §6. The visual parity gate at T103b
(end of US1) must verify the rendered icons against Figma renders;
if SF Symbols differ visually, swap to `mcp__momorph__get_media_files`
exports.

---

## 5 · ABOUT button styling (§3.5 detail)

### ABOUT AWARD (`6885:9026`)

- 160 × 40 pt, padding 12 pt, radius 4 pt, gap 8 pt (label → icon).
- Background: `BrandCream` (`#FFEA9E`).
- Label: `Montserrat 14 / 500 / 20 pt / 0 letter-sp / BrandOnCream`,
  text `"ABOUT AWARD"` (case as-is — UPPERCASE).
- Icon: 24 × 24 pt (component `6885:8012` — same icon as ABOUT KUDOS).

### ABOUT KUDOS (`6885:9027`)

- 159 × 40 pt, padding 10 pt, radius 4 pt, gap 8 pt.
- Background: `BrandCream` at **10 %** alpha (`#FFEA9E1A`).
- Border: 1 pt solid `DropdownBorder` (`#998C5F`).
- Label: `Montserrat 14 / 500 / 20 pt / 0 letter-sp / white`,
  text `"ABOUT KUDOS"`.
- Icon: 24 × 24 pt (same component as ABOUT AWARD).

The 1 pt difference (160 vs 159) between the two buttons is a Figma
rounding artifact — they're each `(335 - 16) / 2 = 159.5 pt` wide.
Implementation can render both at 159 pt or use the wider `160 + 16
+ 159` pattern verbatim — within rounding tolerance.

---

## 7 · US2 Awards section (T104a — appended 2026-04-27)

Drift check: `mcp__momorph__get_frame OuH1BUTYT0` revision
`3c9059f3da88539320cb62e39aefcf38` — equals §0 baseline. PASS.

### 7.1 Section container (`mms_4_awards` — `6885:9030`)

- Frame: **1040 × 375 pt** at (20, 925), vertical flex column,
  gap 24 pt. Width 1040 > 375 (screen) — the `mms_4.2_award list`
  child below is a horizontal-scroll container. The Awards section
  itself anchors at left edge x=20 and extends right past the edge.
- 2 children stacked vertically with gap 24 pt:
  - `mms_4.1_header` (335 × 53 pt) — section title block
  - `mms_4.2_award list` (1040 × 298 pt) — horizontal cards row

### 7.2 Section header (`mms_4.1_header` — `6885:9031`)

Generic section-header component instance, also used by Kudos
(`mms_5.1_header`). Vertical column, gap 4 pt:

| Element        | Size      | Typography                                            | Color           |
|----------------|-----------|-------------------------------------------------------|-----------------|
| Subtitle       | 335 × 16  | Montserrat 12 / 400 / 16 / 0 letter-sp                | white           |
| Divider line   | 335 × 1   | (rectangle fill)                                      | `#2E3940` (NEW) |
| Title row      | 335 × 28  | Montserrat 22 / 500 / 28 / 0 letter-sp                | `BrandCream`    |

For the Awards section the subtitle reads **"Sun\* Annual Awards 2025"**
and the title reads **"Hệ thống giải thưởng"**.

### 7.3 Award cards row (`mms_4.2_award list` — `6885:9032`)

- Frame: 1040 × 298 pt, horizontal flex row, gap 16 pt,
  `alignItems: center`. Renders as a horizontally-scrollable strip
  on iOS (`ScrollView(.horizontal, showsIndicators: false)` with
  `LazyHStack(spacing: 16)`).
- 6 cards in DB (per `award_kind` enum: `mvp / best_manager /
  signature_creator / top_project / top_project_leader /
  top_talent`); 3 visible at rest on a 375 pt screen.

### 7.4 AwardCard (`6885:9033 / 9034 / 9035`)

Each card is **160 × 298 pt**, vertical column, gap 12 pt,
left-aligned. 3 stacked elements:

#### Picture cell (`mm_media_Picture-Award`)
- 160 × 160 pt, `borderRadius: 11.43 pt`, **0.455 pt cream border**,
  shadow `0 1.905px 1.905px 0 rgba(0, 0, 0, 0.25), 0 0 2.857px 0
  #FAE287` (subtle dark drop + pale-yellow glow).
- `mix-blend-mode: screen`.
- Background: per-kind raster PNG (asset key from
  `awards.artwork_asset_key` — see §7.7 Asset inventory).

#### Text block (`Frame 490`)
- 160 × 82 pt, vertical column, gap 2 pt:
  - **Title** (e.g. "Top Talent" / "Top Project" / "Top Project Leader")
    — 160 × 20 pt, Montserrat 14 / 500 / 20 / 0 letter-sp,
    `BrandCream`. Single line, NO truncation pattern needed.
  - **Description** — 160 × 60 pt (3 lines × 20 pt), Montserrat
    14 / 300 / 20 / +0.25 letter-sp, white. **`.lineLimit(3)` with
    truncation tail** ("...") — Figma's example string ends in
    `vinh danh những cá nhân xuất ...`.

#### Detail button (`Button` 6885:7556)
- 84 × 32 pt, padding `10 0 10 0`, `borderRadius: 4 pt`,
  `flex-direction: row`, gap 8 pt, `justifyContent: center`.
- **Background: transparent** (no fill). Visual contrast comes
  from the button's text + arrow icon glyph color.
- Label `"Chi tiết"` — 52 × 20 pt, Montserrat 14 / 500 / 20 / 0
  letter-sp, **white**.
- Trailing icon — 24 × 24 pt arrow (`mm_media_icon` component
  `6885:8012`, same as ABOUT buttons trailing icon — same SVG
  `6886fcd325203fb9712cd76c17411502.svg`).

### 7.5 States (per spec §Component Behavior)

| State    | Render                                                                      |
|----------|-----------------------------------------------------------------------------|
| loading  | 3 placeholder cards with shimmering rectangles (160 × 160 + 160 × 60)       |
| loaded   | Real card list (≥ 1 row from `public.awards`)                               |
| empty    | Replace cards row with single line "Giải thưởng sẽ được công bố sớm."      |
| error    | Replace cards row with inline retry row (text + tap to re-fetch)            |

Empty + error use the localised keys `home.awards.empty` /
`home.awards.error` already in `Localizable.xcstrings`.

### 7.6 Vertical anchor map (Awards section)

```
y =  925 ─── Awards section start
y =  925 → 941 ── subtitle "Sun* Annual Awards 2025" (12pt / 400)
y =  945 → 946 ── divider (#2E3940, 1pt)
y =  950 → 978 ── title "Hệ thống giải thưởng" (22pt / 500 / cream)
y = 1002 ─── cards row top (header end + 24pt gap)
y = 1002 → 1162 ── card pictures (160pt tall)
y = 1174 → 1256 ── card text block (gap 12 from picture; 82pt tall)
y = 1268 → 1300 ── "Chi tiết" buttons (gap 12 from text; 32pt)
y = 1300 ─── Awards section end
```

### 7.7 Asset inventory (Awards)

| xcassets name           | Source                  | Figma Node                   | DB key (`artwork_asset_key`) |
|-------------------------|-------------------------|------------------------------|-------------------------------|
| `awards/award_top_talent`        | PNG raster        | `I6885:9033;72:2115;72:2079` | `award_top_talent`            |
| `awards/award_top_project`       | PNG raster        | `I6885:9034;72:2115;72:2085` | `award_top_project`           |
| `awards/award_top_project_leader`| PNG raster        | `I6885:9035;72:2115;75:1549;81:2442` | `award_top_project_leader` |
| `awards/award_mvp`               | PNG raster        | (TBD — Figma frame currently shows only 3 cards) | `award_mvp`         |
| `awards/award_best_manager`      | PNG raster        | (TBD)                        | `award_best_manager`          |
| `awards/award_signature_creator` | PNG raster        | (TBD)                        | `award_signature_creator`     |

**Note**: Figma frame `OuH1BUTYT0` only shows 3 cards (Top Talent,
Top Project, Top Project Leader) at rest. The other 3 (MVP,
Best Manager, Signature Creator) are catalogued in DB
(migration 0025) but not rendered on Home — they live on the
detail screens which M4 ships. M2 fetches all 6 PNGs at T052
to be ready when DB returns 6 rows; if Figma exports return
`null` for the 3 not-rendered ones, T052 falls back to a
generic placeholder PNG with a deviation note.

---

## 8 · US2 Kudos section (T104a — appended 2026-04-27)

### 8.1 Section container (`mms_5_kudos` — `6885:9039`)

- Frame: **335 × 490 pt** at (20, 1348), vertical flex column,
  gap 24 pt. (Note: 335 not 1040 — Kudos is full-width-of-content,
  no horizontal scroll.)
- 4 children stacked vertically with gap 24 pt:
  - `mms_5.1_header` (335 × 53 pt) — same component as Awards
  - `mms_5.2_mm_media_Sunkudos` (335 × 145 pt) — banner image
  - `note` (335 × 180 pt) — Kudos description paragraph
  - `mms_5.3_Button` (160 × 40 pt) — "Chi tiết" CTA

### 8.2 Header (`mms_5.1_header` — `6885:9040`)

Same layout as §7.2. Subtitle: **"Phong trào ghi nhận"**. Title:
**"Sun\* Kudos"**.

### 8.3 Banner (`mms_5.2_mm_media_Sunkudos` — `6885:9041`)

- Frame: **335 × 145 pt**, vertical column, `alignItems: center`,
  `justifyContent: center`.
- Background `MM_MEDIA_Kudos Background`: 335 × 145.4 pt PNG with
  `#0F0F0F` fallback bg, `borderRadius: 4.653 pt`. Image fetched
  at T053 from Figma node `6885:9043` (export available).
- Center-aligned `MM_MEDIA_Logo/Kudos` group (118 × 21 pt):
  - 23 × 19 small logo glyph at left
  - "KUDOS" wordmark — SVN-Gotham 27.96 pt / 400 / 6.99 line-height
    / -13% letter-sp / **`#DBD1C1` (NEW)** — light cream/parchment
    color. iOS substitution: SF Pro Display Bold at the same size,
    documented as a deviation (#10).

### 8.4 Note paragraph (`note` — `6885:9053`)

- Frame: 335 × 180 pt at (20, 1594), single TEXT child `6885:9054`.
- Typography: **Montserrat 14 / 300 / 20 / +0.25 letter-sp / white**.
- **Real VN copy from Figma** (replaces M2 placeholder
  `home.kudos.note` draft):
  > ĐIỂM MỚI CỦA SAA 2025
  >
  > Hoạt động ghi nhận và cảm ơn đồng nghiệp - lần đầu tiên được
  > diễn ra dành cho tất cả Sunner. Hoạt động sẽ được triển khai
  > vào tháng 11/2025, khuyến khích người Sun\* chia sẻ những lời
  > ghi nhận, cảm ơn đồng nghiệp trên hệ thống do BTC công bố.
  > Đây sẽ là chất liệu để Hội đồng Heads tham khảo trong quá
  > trình lựa chọn người đạt giải.
- Figma frame contains VN only — EN follows §6 #6 protocol
  (state: needs_review with VN fallback).

### 8.5 Detail button (`mms_5.3_Button` — `6885:9055`)

- 160 × 40 pt at (20, 1798), padding 12 pt all sides,
  `borderRadius: 4 pt`, gap 8 pt, `justifyContent: center`.
- Background: `BrandCream` (`#FFEA9E`) — same as ABOUT AWARD.
- Label "Chi tiết" — Montserrat 14 / 500 / 20 / 0 letter-sp /
  `BrandOnCream`.
- Trailing icon — 24 × 24 pt (component `6885:8012`, shared SVG).

### 8.6 Vertical anchor map (Kudos section)

```
y = 1348 ─── Kudos section start
y = 1348 → 1364 ── subtitle "Phong trào ghi nhận"
y = 1368 → 1369 ── divider
y = 1373 → 1401 ── title "Sun* Kudos" (cream)
y = 1425 → 1570 ── banner (335×145 image)
y = 1594 → 1774 ── note paragraph (335×180)
y = 1798 → 1838 ── "Chi tiết" CTA (160×40)
y = 1838 ─── Kudos section end
```

### 8.7 Asset inventory (Kudos)

| xcassets name        | Source       | Figma Node    | Status       |
|----------------------|--------------|---------------|--------------|
| `KudosBanner`        | PNG          | `6885:9043`   | NEW — fetch at T053 |
| (KUDOS wordmark text)| system font  | `6885:9046`   | iOS subst — deviation #10 |

---

## 9 · US4 FAB (T106a — appended 2026-04-27)

Drift check: revision `3c9059f3da88539320cb62e39aefcf38` — equals §0
baseline. PASS.

### 9.1 Outer container (`mms_6_float button` — `6885:9058`)

- Position: **(266, 1790) → (355, 1838) = 89 × 48 pt**, anchored
  trailing-bottom of the screen content (above the BottomTabBar via
  `safeAreaInset`). The FAB **does not scroll with content** — it
  is overlaid on the HomeView via `.overlay(alignment: .bottomTrailing)`.
- Shadow: dark drop + pale-yellow glow:
  - `0 4px 4px 0 rgba(0, 0, 0, 0.25)`
  - `0 0 6px 0 #FAE287`
- Z-index above the BottomTabBar.

### 9.2 Inner button (`I6885:9058;75:2162`)

- Frame: 89 × 48 pt, **pill shape** (`borderRadius: 100 pt`).
- Background: `BrandCream` (`#FFEA9E`).
- Padding: 8 pt all sides.
- Gap: 8 pt between the two children.
- Horizontal flex, `align-items: center`.

### 9.3 Two tap zones inside the pill

The pill is **one visual element**, but the spec (US4 + Q3 default)
treats it as **two distinct tap zones**:

| Zone | Visual element | Position (within pill) | Tap target | Action |
|------|----------------|------------------------|------------|--------|
| **Compose** (pen) | `MM_MEDIA_Pen` 24×24 (`I6885:9058;75:2164`) + `/` separator 9×32 (`I6885:9058;75:2165`) | left half: pen at x=274–298, separator at x=306–315 | Padding-extended to **44 pt min target** per HIG | `viewModel.fabComposeTapped.accept(())` → `navigate(.writeKudo)` |
| **Open Kudos feed** (S logo) | `MM_MEDIA_IC_Kudos Logo` 24×24 (`I6885:9058;75:2166`) | right half: x=323–347 | Padding-extended to **44 pt min target** | `viewModel.fabKudosFeedTapped.accept(())` → `navigate(.sunKudos)` |

The `/` separator (at x=306, 9 pt wide) is a **visual divider only**
— Montserrat 24 / 400 / 32 line-height / `BrandOnCream`. iOS
substitution: SF Pro Bold at 24 pt, same color. It sits between the
two tap zones and visually communicates "two actions, one element".

#### Tap-zone geometry

The 73 pt content area (89 - 2×8 padding) splits as:
- **Compose zone**: covers the pen icon + the `/` separator → x=8 to
  x=49 (within button), width 41 pt. Includes the separator so the
  user has a clear "left half" target.
- **Kudos feed zone**: covers the S icon → x=49 to x=81, width 32 pt.

Each `Button` view extends its `contentShape` to a **44 × 44 pt
hit-test rectangle** (HIG-min) regardless of the icon's visual
24 × 24 size.

### 9.4 Behavioural specs (per spec US4)

- **Debounce**: each zone has its own `throttle(.milliseconds(300),
  latest: false)` so a rapid double-tap on either zone fires only
  once. Per-zone, not shared — tapping pen then S quickly should
  fire BOTH.
- **In-flight guard** (US4 AS3 + AS5): a per-zone `BehaviorRelay<Bool>`
  flips to `true` on emit and is cleared on `viewAppeared`. So the
  "tap, navigate away, return to Home" cycle re-arms both zones.
- **Position**: trailing-bottom anchored, **fixed** (no scroll). When
  the user scrolls Home down, the FAB stays put above the tab bar.
- **VoiceOver**:
  - Pen zone: `accessibilityLabel = "Viết Kudo"` (`home.fab.compose.label`),
    `accessibilityHint = "Ghi nhận đồng nghiệp"` (`home.fab.compose.hint`).
  - Kudos S zone: `accessibilityLabel = "Mở Sun*Kudos"` (`home.fab.feed.label`).

### 9.5 Asset inventory (FAB)

| xcassets name        | Source           | Figma Node                      | Status |
|----------------------|------------------|---------------------------------|--------|
| (pen icon)           | Figma component (returns null) | `I6885:9058;75:2164`        | iOS substitution: SF Symbol `pencil` (deviation §6 #5 PERMANENT pattern) |
| (Kudos S logo)       | Figma component (returns null) | `I6885:9058;75:2166`        | iOS substitution: SF Symbol `s.circle.fill` or custom asset (deviation §6 #5 — fetch real SVG at T106b if Figma export is added later) |
| (separator `/`)      | text             | `I6885:9058;75:2165`            | rendered as `Text("/")` with SF Pro Bold 24 pt |

The pen + Kudos S icons return `null` from `mcp__momorph__get_media_files`
on this frame (per the M2 PR-M2.1 known-deviation #5), same as the
search/bell icons. SF Symbols substitution is canonical. The `/`
separator is text — no asset needed.

### 9.6 Position anchor map (FAB)

```
y = 1790 ─── FAB top (above BottomTabBar at y=1870, so 80pt clearance)
y = 1838 ─── FAB bottom
x =  266 ─── FAB left edge (89pt wide → ends at x=355)
```

On iOS, anchored via `.overlay(alignment: .bottomTrailing)` on the
HomeView ScrollView with a 20 pt trailing inset and a vertical
inset that places the FAB **above the BottomTabBar's safe-area inset**
— matches Figma's 32 pt clearance (1870 - 1838 = 32 pt).

---

## 10 · US8 BottomTabBar (T109a — appended 2026-04-27)

Drift check: revision unchanged. PASS.

### 10.1 Container (`mms_7_nav bar` — `6885:9056`)

- Outer: 375 × 72 pt at y=1870 → 1942 (full-width, anchored bottom).
- Inner `nav bar` frame: 375 × 72, padding `0 24`, background
  **`rgba(255, 234, 158, 0.15)`** (BrandCream at 15 %), border-radius
  **`20 20 0 0`** (top corners only), `backdrop-filter: blur(20px)`.
- Inside `Tabs` 375 × 54 sub-frame: padding `0 24`, justify-content
  space-between → 4 evenly distributed tab items.

### 10.2 Tab item layout (4× 60 × 44 frame)

- Each tab: 60 × 44 pt, vertical flex column, gap 4 pt, alignItems center.
- Layout per item: icon (top, ~24×24) + label below (font small).
- Position per tab (from Figma, x ranges):
  - SAA: x=24–84
  - Awards: x=113–173
  - Kudos: x=202–262
  - Profile: x=291–351

### 10.3 Active vs inactive states

Figma frame doesn't render an "active" highlight pill; the active
state is communicated by **icon/label color**:
- Active: `BrandCream` (`#FFEA9E`)
- Inactive: white at 65 % opacity

### 10.4 Icon assets

| Tab     | Figma SVG node              | iOS substitute (M2) |
|---------|------------------------------|---------------------|
| SAA     | `I6885:9056;75:2010` (SVG export available) | `house.fill` (SF Symbol) |
| Awards  | `I6885:9056;75:2013` (SVG)    | `trophy.fill`         |
| Kudos   | `I6885:9056;75:2016` (SVG)    | `hands.sparkles.fill` |
| Profile | `I6885:9056;75:2019` (SVG)    | `person.crop.circle.fill` |

Real SVGs **are exported** by Figma — the SF Symbols substitution
is for PR-M2.5 ship velocity. T109b verifies side-by-side and may
swap to bundled SVGs if Designer flags the deviation. Documented as
deviation §6 #12 (NEW, OPEN).

### 10.5 Position anchor map (BottomTabBar)

```
y = 1870 ─── tab bar top (full-width, top-corner radius 20)
y = 1875 ─── tab item content top (5pt inset)
y = 1919 ─── tab item content bottom (44pt tall)
y = 1942 ─── screen bottom
```

The 23pt gap between tab content bottom (1919) and screen bottom
(1942) accommodates the iPhone home-indicator safe area on
notched devices. iOS `safeAreaInset(.bottom)` mounts the bar above
the system safe-area, matching the Figma anchor.

### 10.6 Re-tap semantics (US8 AS4)

- Tab tap when **inactive** → `TabRouter.set(_)` updates `selectedTab`
  → RootView's `onChange(of:)` resets the AppRoute to that tab's
  primary destination.
- Tab tap when **active** → `TabRouter.notifyTap(_)` sees same tab
  → emits `activeTabReTapped(tab)` event:
  - HomeViewModel filters this to `.saa` → emits
    `scrollTo: Signal<HomeAnchor>` of `.top`
  - RootView listens too: if user is NOT on the tab's primary
    route (e.g. drilled into award detail), reset to primary.

---

## Color tokens added in T104a

Append to §1 palette:

| Token (xcassets name) | Hex      | Used by                                              |
|-----------------------|----------|------------------------------------------------------|
| `Divider`             | `#2E3940`| Section header dividers (Awards + Kudos)             |
| `KudosBannerBg`       | `#0F0F0F`| Kudos banner fallback bg when image fails to load    |
| (computed)            | `#DBD1C1`| Kudos banner "KUDOS" wordmark text                   |

The `#FAE287` glow color (already used in ABOUT AWARD shadow + FAB
shadow) is reused on AwardCard picture shadows.

---

## 6 · Known deviations from this spec

Each entry needs Designer sign-off; any new deviation MUST be
appended here, not silently introduced in code. Status legend:
**OPEN** = needs follow-up, **CLOSED** = resolved at T103b,
**PERMANENT** = intentional ongoing deviation.

1. **OPEN — Header gradient stop count.** MCP `list_frame_styles`
   returned a 7-stop curve (`1.00 → 0.30 @ 76.44% → 0.20 → 0.15 →
   0.10 → 0.05 → 0.00`). M1 Login established a canonical 4-stop
   pattern (`1.00 / 0.90 / 0.60 / 0.00` evenly distributed). The
   visual delta is non-trivial: the 7-stop holds opacity longer at
   the top (sharper dark band), the 4-stop fades sooner. T103b
   could not access Figma's color picker from CLI to confirm which
   is canonical. Implementation kept the M1 4-stop pattern for
   consistency. **Next step**: Designer review on M2 PR-M2.2 ship —
   if the 7-stop matches their picker, update `HomeView.body`'s
   LinearGradient stops and re-verify.

2. **PERMANENT — Font family**: Montserrat → SF Pro (system).
   Decision inherited from M1 design-style; identical line-heights,
   weights approximate. Bundling Montserrat .ttf + registering via
   `Info.plist` is a future M-level task.

3. **PERMANENT — Flag glyphs in chip**: Figma exports return `null`
   for the country-flag SDK instances. iOS substitutes emoji `🇻🇳`
   / `🇬🇧` (system-rendered, scales with Dynamic Type). Inherited
   from M1.

4. **PERMANENT — Chip background**: Figma chip has no fill; iOS
   adds a 30 %-black tint (`ChipBackground` Color Set) to preserve
   contrast over a bright keyvisual. Inherited from M1.

5. **PERMANENT — Search + bell icons**: Figma `get_media_files`
   returns `null` for `I6885:9057;88:1869` (search), `I6885:9057;88:1830`
   (bell), and `I6885:9057;88:1830;72:1627` (dot wrapper) — they are
   SDK-rendered primitives Figma can't materialize. SF Symbols
   substitution (`magnifyingglass` / `bell`) is the canonical iOS
   path, not a placeholder. Reclassified at T103b from "OPEN
   pending fetch" to "PERMANENT — Figma export limitation".

6. **OPEN — `home.theme.note` EN copy**: Figma provides VN only.
   The xcstrings `en` slot temporarily mirrors the VN string with
   `state: needs_review` until the Content team supplies the EN
   translation. **Next step**: Content team adds EN string;
   `home.theme.note` flips to `state: translated`.

7. **CLOSED — Bell unread-dot color** (resolved 2026-04-27 at
   T103b). Drilled into node `I6885:9057;88:1830;72:1627;72:1628`
   (the actual dot Frame): `backgroundColor: rgba(212, 39, 29, 1)`
   = **`#D4271D`** (deep red). `UnreadDotBadge` updated to use the
   exact Figma color via `Color(red: 212/255, green: 39/255, blue:
   29/255)`. PR-M2.2 placeholder `Color.red` (`#FF3B30`) replaced.

8. **OPEN — ABOUT button trailing icon**: Figma SVG asset exists
   at `I6885:9026;28:1997` (ABOUT AWARD) and `I6885:9027;28:2029`
   (ABOUT KUDOS) — both reference the same shared SVG
   `6886fcd325203fb9712cd76c17411502.svg`. Implementation uses SF
   Symbol `arrow.right` for PR-M2.2 part 1 (visually similar 24×24
   right-arrow). **Next step**: download the SVG via
   `mcp__momorph__get_media_files`, convert to xcassets, swap.
   Acceptable to defer to a polish task — visual delta is small.

9. **OPEN — Event info value bindings**: `HomeView.formattedDate`
   currently hard-codes `Date(timeIntervalSince1970: 1_766_761_200)`
   (`26/12/2025 19:00 +07`) and "Âu Cơ Art Center" verbatim instead
   of binding to `AppConfig.eventTargetDate` / `eventPlace` via the
   ViewModel. Behavior is correct (matches current xcconfig values)
   but couples HomeView to a magic constant. **Next step**: extend
   `HomeViewModel` to expose `eventSchedule: EventSchedule` (or a
   formatted string Driver) and bind from `HomeStateAdapter`.
   Acceptable to defer to a polish task — values are correct today.

12. **OPEN — BottomTabBar tab icons**: Figma exports SVGs for all 4
    tab icons (SAA / Awards / Kudos / Profile). PR-M2.5 ships with
    SF Symbols substitutes (`house.fill / trophy.fill /
    hands.sparkles.fill / person.crop.circle.fill`) for ship velocity.
    **Next step**: T109b verify side-by-side; if visual delta is
    significant, fetch the 4 SVGs via `mcp__momorph__get_media_files`
    and bundle them. Acceptable to defer to a polish task.

10. **PERMANENT — Kudos banner "KUDOS" wordmark font**:
    Figma uses **SVN-Gotham 27.96 pt / 400 / -13% letter-sp** for
    the wordmark on the Kudos banner. iOS does not ship SVN-Gotham.
    Substitution: **SF Pro Display Bold** at 28 pt with -3.6 letter-sp
    (≈ -13% of 28pt). Visual weight + tracking approximate; same
    parchment-tone color `#DBD1C1`. Inherited from M1 Montserrat→SF
    Pro substitution rationale (deviation #2).

---

## Append log

- **2026-04-27 — T103a (seed)**: global tokens, header, hero, theme
  paragraph specs.
- **2026-04-27 — T103b (verify, US1 close)**: drift check + 4
  resolutions:
  1. **Drift-check PASS** — `mcp__momorph__get_frame OuH1BUTYT0`
     returned revision `3c9059f3da88539320cb62e39aefcf38` (same as
     §0 baseline). No frame change since seed.
  2. **Bell dot color** (deviation #7) → CLOSED at `#D4271D`.
     `UnreadDotBadge` updated.
  3. **Search + bell + FAB icons** (deviation #5) → reclassified
     from OPEN to PERMANENT after `mcp__momorph__get_media_files`
     returned `null` for all three nodes — Figma has no exportable
     asset to swap to. SF Symbols substitution stands as canonical.
  4. **ABOUT button trailing icon** (deviation #8, NEW) — Figma
     has SVG export for the small right-arrow. Implementation uses
     SF Symbol `arrow.right` for PR-M2.2 part 1 ship; swap deferred
     as polish task (visual delta is small).
  5. **Event info bindings** (deviation #9, NEW) — `formattedDate`
     + venue currently hard-coded in `HomeView`. Defer to polish
     task; values are correct but coupling smells.
  6. **Header gradient stops** (deviation #1) → STILL OPEN.
     Designer review required at PR-M2.2 ship to pick between the
     M1 4-stop pattern (in code) and the MCP-reported 7-stop curve.
  - **Side-by-side screenshot check**: deferred — taking a Home
    screenshot from the simulator requires bypassing the Login →
    Home gate, which depends on a launch-arg hook (T029 same gap).
    Code-review against §3 specs flagged the 9 deviations above;
    no other layout / spacing / typography mismatches.
- (T104 / T105 / T106 / T107 / T109 / T110 append their per-component
  sections here as the corresponding US phases ship.)
- **2026-04-28 — Visual sweep follow-up: fixes from rendered-app screenshot review**:
  Designer review of the running app (vs Figma frame) caught 3
  bugs that the code-only review missed:
  1. **Keyvisual stretch** — `Image("KeyvisualBackground").scaledToFill()`
     was filling the entire 1942-pt scrollable content area, making
     the orange/blue/green wave-art dominate the screen instead of
     anchoring to the top 812-pt band per §3.1. Fix: wrap in `VStack`
     with explicit `.frame(height: 812)` + `.clipped()` + `Spacer()`
     so the image stays contained at top and the rest of the screen
     renders over the solid `BrandOnCream` background.
  2. **`%@` literal** in event info — `home.event.time / .place /
     .livestream` localisation values had `%@` placeholders meant
     for `String(format:)` but were rendered as plain
     `LocalizedStringKey` + separate value Text, leaving the `%@`
     visible to users. Fix: rewrite the localisation values as
     **labels only** (`"Time:" / "Thời gian:"`, `"Place:" / "Địa
     điểm:"`, `"Live broadcast at Group Facebook Sun* Family"`).
     The value (date / place) is rendered as a separate Text with
     the cream emphasised style, no format-string substitution
     needed.
  3. **Tab bar bleeds keyvisual** — the `.ultraThinMaterial`
     frosted-blur on `BottomTabBar` was reading the keyvisual
     pixels behind it, producing the wrong tint. Resolved by fix
     #1 (keyvisual contained → tab bar's blur reads solid
     `BrandOnCream`, looks correct).
  All 3 fixes applied to `HomeView.swift` + `Localizable.xcstrings`
  in this same Test Flight cycle.
- **2026-04-28 — Visual sweep follow-up #2: keyvisual scroll + tab-bar bleed fix**:
  Round 2 of feedback — keyvisual still bled the tab bar's
  frosted-blur because `.background()` modifier on a `ScrollView`
  pins to the **viewport** (the visible window), not the content.
  At scroll-position 0 on iPhone 17, the 812-pt keyvisual covers
  ~95% of the 852-pt viewport, including the tab-bar zone at the
  bottom (y=780–852). The tab bar's `.ultraThinMaterial` blur reads
  the keyvisual's colours instead of dark.
  - **Fix**: moved keyvisual + gradient INSIDE `ScrollView`
    content (now first child of the `ZStack(alignment: .top)`
    wrapper around `contentStack`). The keyvisual scrolls UP and
    out of view as the user scrolls down; the rest of the
    ScrollView area sits over solid `BrandOnCream` set via
    `.background(Color("BrandOnCream"))` + `.scrollContentBackground(.hidden)`.
    Tab bar's blur now always reads clean dark.
  - **Bottom fade** added to keyvisual: a 200-pt vertical gradient
    fading from transparent (top) to `BrandOnCream` (bottom) over
    the last 200 pt of the 812-pt band. Removes the hard edge at
    y=812 and matches the soft fade visible in the Figma render.
  - The previous outer-ZStack approach (keyvisual fixed in viewport)
    was reverted — it caused a side effect where ScrollView content
    rendered through the safe-area top, hiding the header behind the
    status bar.
- **2026-04-28 — Visual sweep follow-up #3: bottom-bar gap + content bleed**:
  Round 3 of feedback: the BottomTabBar didn't extend to the screen
  bottom (visible gap above the home indicator) and Kudos note
  paragraph content bled BELOW the tab bar position. Two distinct
  bugs:
  1. **`.background(...).ignoresSafeArea()` on outer HomeView level
     overrode RootView's `.safeAreaInset(.bottom) { BottomTabBar }`**.
     The `safeAreaInset` reserves space above the tab bar for content;
     `.ignoresSafeArea()` on HomeView's wrapper background defeated
     that, so ScrollView content extended through the tab bar zone.
     **Fix**: changed outer background to `.ignoresSafeArea(edges: .top)`
     only — top safe area still bleeds dark beneath the keyvisual,
     bottom safe area is owned by RootView's tab-bar inset.
  2. **BottomTabBar's `.clipShape` was applied to the WHOLE bar
     (HStack + background)** — clipping the cream-15% + blur to a
     fixed 72-pt frame, never extending into the home indicator
     zone. **Fix**: moved `.clipShape` INSIDE the `.background {}`
     so it only shapes the background view; added
     `.ignoresSafeArea(edges: .bottom)` on the background so it
     extends visually through the home indicator while the tap
     target stays at 72 pt above the safe area.
- **2026-04-28 — Visual sweep follow-up #4: tab bar still showed gap
  + transparent bleed**:
  Round 4 of feedback: the bar background still didn't reach the
  screen bottom and ScrollView content was visible "behind" the
  tab bar. Two combined causes:
  - `.ignoresSafeArea(edges: .bottom)` applied to the BACKGROUND
    view inside `.background {}` is layout-only — the parent view's
    rendering bounds were still 72 pt, so the bg extension was
    invisible.
  - `.ultraThinMaterial` + 15 % cream is genuinely transparent —
    even with the bg correctly extended, content above the bar
    showed through.
  - **Fix**: applied `.ignoresSafeArea(edges: .bottom)` to the
    ENTIRE `BottomTabBar` view (the modifier extends the
    rendering bounds; LAYOUT size reported to `safeAreaInset(.bottom)`
    stays at 72 pt for the tap-target). Stacked an opaque
    `Color("BrandOnCream")` BENEATH `.ultraThinMaterial` + cream-
    15 % so the bar is solid enough to mask content while keeping
    the frosted-glass tint.
- **2026-04-28 — End-of-screen visual sweep (T103b + T106b + T109b)**:
  - **Drift check** — `mcp__momorph__get_frame OuH1BUTYT0` returns
    revision `3c9059f3da88539320cb62e39aefcf38` (unchanged from §0
    baseline established at T103a). PASS.
  - **Figma frame fetched** — full PNG (375×1942 pt) downloaded via
    `mcp__momorph__get_frame_image` and visually inspected.
  - **Code-level review** of `HomeView` + sub-views against §3 (Header
    + Hero + Theme), §7 (Awards), §8 (Kudos), §9 (FAB), §10 (TabBar)
    sections — all structural elements present and positioned
    correctly per anchor maps. Asset substitutions (SF Symbols for
    search / bell / FAB / tab icons; arrow.right for ABOUT / Chi tiết
    trailing icon; SF Pro Bold for KUDOS wordmark) applied per
    documented deviations §6 #1, #5, #8, #10, #12.
  - **Side-by-side simulator screenshot** — DEFERRED. The sim
    requires an authenticated session to reach Home, and a
    launch-arg hook to bypass auth (the same hook that gates T029 /
    T054 / T070 / T075 / T079 / T083 / T090 / T094 XCUITests). When
    that hook lands as a follow-up task, this entry is updated with
    the screenshot.
  - **Outstanding visual-fidelity items** (already in §6, kept open
    pending Designer review at PR-M2.5):
    - #1 Header gradient stops (M1 4-stop vs MCP-reported 7-stop)
    - #8 ABOUT button trailing icon (SVG available, SF Symbol used)
    - #9 Event info hard-coded values (defer to polish)
    - #12 BottomTabBar icons (SVG available, SF Symbols used)
  - **Result**: PR-M2 ready to merge with these 4 deviations
    documented; Designer reviews the visual delta on a Test Flight
    build before public ship.
