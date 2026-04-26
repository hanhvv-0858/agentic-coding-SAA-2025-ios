# Design Style — `[iOS] Login` (`8HGlvYGJWq`) + `[iOS] Language dropdown` (`uUvW6Qm1ve`)

**Source**: Figma file `9ypp4enmFmdK3YAFJLIu6C`, extracted via
`mcp__momorph__list_frame_styles` on 2026-04-27.
**Canvas**: 375 × 812 pt (iPhone X-class baseline; 1pt = 1px).

---

## 1 · Color tokens

All colors are sourced verbatim from Figma `styles.backgroundColor` /
`styles.fill` / Figma file variables (`Details-Border`,
`Details-Container-2`).

| Token (xcassets name)        | Hex           | Alpha | Used by                                    |
|------------------------------|---------------|-------|--------------------------------------------|
| `BrandCream`                 | `#FFEA9E`     | 1.00  | Sign-in CTA background; selected row tint  |
| `BrandOnCream`               | `#00101A`     | 1.00  | CTA label; any text on cream surface       |
| `DropdownBackground`         | `#00070C`     | 1.00  | Language picker dropdown card              |
| `DropdownBorder`             | `#998C5F`     | 1.00  | 1 pt stroke around the dropdown card       |
| (computed)                   | `#FFEA9E`     | 0.20  | Selected dropdown row tint                 |
| `BackgroundFallback`         | `#00101A`     | 1.00  | Behind keyvisual & header gradient         |
| (system) `.white`            | `#FFFFFF`     | 1.00  | All body text, chip text, footer           |

The header has a **top-fade gradient overlay** (its own layer above the
keyvisual, full-width, 104 pt tall) with 4 stops, all `#00101A` at
descending alpha, evenly distributed along the gradient line:

| Stop | Position | Color    | Alpha |
|------|----------|----------|-------|
| 1    | 0 %      | `#00101A`| 1.00  |
| 2    | 33.33 %  | `#00101A`| 0.90  |
| 3    | 66.67 %  | `#00101A`| 0.60  |
| 4    | 100 %    | `#00101A`| 0.00  |

This is the canonical definition straight from Figma's color picker.
The MCP `list_frame_styles` tool earlier returned a 7-stop CSS
approximation (curve-fit with extra in-between stops) — that output is
NOT canonical; trust the picker.

This gradient gives the logo + chip readable contrast against the busy
keyvisual. **Do not omit.**

---

## 2 · Typography

Design uses **Montserrat** (300 / 400 / 500). iOS does not ship
Montserrat. Approved substitution: **SF Pro (system font)** at the same
sizes / weights — Designer sign-off recorded 2026-04-27 (informally,
captured here as the canonical decision until ratified). When budget
allows, bundle Montserrat .ttf files and register via `Info.plist`.

| Role               | Family      | Size  | Weight | Line-h | Letter-sp | Color         | Align  |
|--------------------|-------------|-------|--------|--------|-----------|---------------|--------|
| Welcome content    | Montserrat  | 14 pt | 300    | 20 pt  | +0.25     | white         | LEFT   |
| CTA label          | Montserrat  | 14 pt | 500    | 20 pt  | 0         | `BrandOnCream`| CENTER |
| Chip "VN" text     | Montserrat  | 14 pt | 500    | 20 pt  | 0         | white         | CENTER |
| Dropdown row text  | Montserrat  | 14 pt | 500    | 20 pt  | +0.10     | white         | CENTER |
| Footer             | Montserrat  | 12 pt | 400    | 16 pt  | 0         | white         | CENTER |

---

## 3 · Component specs

### 3.1 Frame & background

- Screen: **375 × 812 pt**, fallback `BackgroundFallback`.
- Keyvisual: full-bleed `KeyvisualBackground` PNG, 375 × 812.

### 3.2 Header (fixed 104 pt, anchored to top edge)

| Element              | Position (x, y → x', y')      | Size   | Notes                              |
|----------------------|-------------------------------|--------|------------------------------------|
| Status bar           | 0, 0 → 375, 44               | 375×44 | system                             |
| Brand logo (`mms_2`) | 20, **52** → 68, 96          | 48×44  | 8 pt below status bar; left edge   |
| Language chip        | 265, **64** → 355, 96        | 90×32  | 20 pt below status bar; right edge |
| Header gradient      | 0, 0 → 375, 104              | 375×104| see §1                             |

**Logo and chip are NOT vertically centered with each other** — logo
top is 52 pt, chip top is 64 pt (a 12 pt offset). Centering both via a
plain `HStack` produces a small visual delta; acceptable trade-off
unless the screen ships to design-pedantic stakeholders.

### 3.3 Language chip (`mms_2.1_language` — `6885:8976`)

- Size: 90 × 32 pt
- Padding: `4 0 4 8` (T R B L)
- Border-radius: 4 pt
- Background: **transparent** (no fill in design — visual contrast
  comes from the header gradient + keyvisual). Implementation MAY add
  a soft black tint (e.g. 25 %) for cases where the keyvisual is too
  bright; document as a known deviation.
- Inner: flag icon 24×24, "VN" text (see §2), `gap: 8` to the chevron
  (also 24×24).
- Tap target: pad up to 44×44 per HIG (Constitution II).

### 3.4 Hero "ROOT FURTHER" (`mms_3` — `6885:8967`)

- Size: **247 × 109 pt** (raster PNG, asset `HeroLogo`).
- Position: 20, 252 → 267, 361 (left edge gutter 20 pt).
- Aspect ratio is fixed by the source PNG (2.27:1).

### 3.5 Welcome text (`mms_4_content` — `6885:8968`)

- Size: 335 × 40 pt (= 2 lines × 20 pt line-height).
- Position: 20, 393 → 355, 433.
- Width derives from screen width minus 20 pt gutters each side.
- 32 pt vertical gap from the hero's bottom edge.

### 3.6 Sign-in CTA (`mms_5_Button` — `6885:8969`)

- **Size: 246 × 40 pt** (NOT full-width). Centered horizontally
  (`(375 − 246) / 2 = 64.5 pt` left margin).
- Position: 65, 626 → 311, 666.
- Background: `BrandCream` (`#FFEA9E`).
- Border-radius: **4 pt**.
- Padding: 12 pt all sides, internal flex row `gap: 8`.
- Layout: `Label` (text) → `mm_media_icon` (Google G).
- Text: see §2 CTA label row.
- Icon: 24 × 24 pt (full-color Google G SVG).

### 3.7 Footer (`6885:8970`)

- Frame: 375 × 48 pt at y = 764 → 812 (`padding: 16 90 16 90`).
- Text: 196 × 16 pt, centered horizontally inside the frame.
- See §2 Footer row.

### 3.8 Vertical anchor map (375 × 812 baseline)

```
y =   0 ─── status bar top
y =  44 ─── status bar bottom
y =  52 ─── brand logo top         (gap from status bar = 8)
y =  64 ─── chip top               (gap from status bar = 20)
y =  96 ─── logo bottom + chip bottom
y = 104 ─── header frame bottom
y = 252 ─── hero top               (gap from header = 148)
y = 361 ─── hero bottom
y = 393 ─── welcome top            (gap from hero  = 32)
y = 433 ─── welcome bottom
y = 626 ─── CTA top                (gap from welcome = 193)
y = 666 ─── CTA bottom
y = 780 ─── footer text top        (gap from CTA = 114)
y = 796 ─── footer text bottom
y = 812 ─── screen bottom          (gap from text = 16)
```

On notched / Dynamic-Island devices (iPhone 17 family), the safe-area
top is taller than 44 pt — anchor `header` to the safe-area top with the
same 8 pt logo / 20 pt chip insets, and let the bottom Spacer absorb
the device-height delta.

---

## 4 · Language dropdown (`uUvW6Qm1ve`)

The dropdown frame inherits the entire Login layout and overlays a
**Dropdown-List card** at the top-right. The Login behind it stays
fully visible.

### 4.1 Dropdown card (`mms_A_Dropdown-List` — `6891:15595`)

- Position: 233, 96 → 355, 188 (anchored at chip's bottom-right).
- Width: 122 pt; height: 92 pt (with 6 pt padding + 2 × 40 pt rows).
- Padding: 6 pt all sides.
- Background: `DropdownBackground` (`#00070C`).
- **Border: 1 pt solid `DropdownBorder` (`#998C5F`).** ← do not omit.
- Border-radius: 8 pt.
- Shadow (not in Figma but recommended for visual lift): black 35 %,
  blur 16, y-offset 6.

### 4.2 Dropdown rows

Each row: 110 × 40 pt, padding 16 pt, `borderRadius: 2`, internal flex
row `space-between` with the flag-icon + text group on the left.

| State        | Background                               | Text weight  |
|--------------|------------------------------------------|--------------|
| Selected     | `BrandCream` at **20 %** (`#FFEA9E33`)   | 500          |
| Unselected   | transparent                              | 500 (same)   |

The flag icon is a separate 24 × 24 raster (Figma node returns `null`
for media files — emoji `🇻🇳` / `🇬🇧` is the iOS substitute).

---

## 5 · Asset inventory

| xcassets name        | Source PNG/SVG dimensions | Figma node ID                  | Role           |
|----------------------|---------------------------|--------------------------------|----------------|
| `KeyvisualBackground`| 375 × 812 PNG             | `6885:8965`                    | full-bleed bg  |
| `BrandLogoSmall`     | 52 × 48 PNG               | `6885:8977`                    | header logo    |
| `HeroLogo`           | 451 × 200 PNG (display 247 × 109)| `6885:8967`              | wordmark hero  |
| `GoogleG`            | SVG (vector)              | `I6885:8969;28:1997`           | CTA icon       |
| (none — emoji)       | n/a                       | flag node returned `null`      | chip flag      |

---

## 6 · Known deviations from this spec

These are intentional substitutions captured at design-style write
time. Each one needs Designer sign-off; any new deviation MUST be
appended here, not silently introduced in code.

1. **Font family**: Montserrat → SF Pro (system). Visual weight
   approximate; line-heights identical.
2. **Flag glyphs**: Figma exports return `null` for the SDK-rendered
   country-flag instances. iOS substitution = emoji `🇻🇳` / `🇬🇧`
   (system-rendered, scales with Dynamic Type).
3. **Chip background**: Figma chip has no fill (relies on header
   gradient). Implementation MAY add a 25 %-black tint for keyvisual
   robustness (decided per-screen).
