# Feature Specification: Home (SAA 2025 tab)

**Frame ID**: `OuH1BUTYT0` (node `6885:8978`)
**Frame Name**: `[iOS] Home`
**File Key**: `9ypp4enmFmdK3YAFJLIu6C`
**Related screen specs**: [home.md](../../contexts/screen_specs/home.md),
[login.md](../../contexts/screen_specs/login.md) (header chip is shared)
**Created**: 2026-04-27
**Status**: Draft

---

## Overview

Home is the **root tab of the authenticated app** — the SAA 2025 tab.
It is the marketing/brand landing that introduces Sunners to the
**Sun\* Annual Awards 2025** event and the new **Sun\*Kudos** programme.

It bundles four kinds of value into one scrollable surface:

1. **Event awareness** — a real-time countdown to event day
   (26/12/2025, Âu Cơ Art Center), date / venue / livestream copy.
2. **Awards browsing** — horizontally scrollable teaser of the SAA 2025
   award categories, each with a "Chi tiết" deep-link into the
   award-detail screen.
3. **Kudos onboarding** — a banner-led section explaining Sun\*Kudos as
   the new SAA recognition movement, with a "Chi tiết" CTA into the
   Kudos feed.
4. **Quick-access shell** — header (logo + language chip + search +
   notifications), a floating action button to compose a Kudo, and a
   four-tab bottom bar (`SAA 2025` / `Awards` / `Kudos` / `Profile`).

**Target users**: authenticated Sunners (`@sun-asterisk.com` allowlist
applies upstream — every visitor here has a valid Supabase session).

**Business context**: Home replaces the M1 placeholder. It is the
**first authenticated surface** every user sees on cold launch; trust,
load speed, and clarity here drive adoption of the awards + Kudos
flows, both of which depend on Home as their entry point. The screen
is part of the **M2 App-shell** milestone (per
[IMPLEMENTATION_ROADMAP.md § M2](../../contexts/IMPLEMENTATION_ROADMAP.md)).

---

## User Scenarios & Testing *(mandatory)*

### User Story 1 — Land on Home with countdown & event info (Priority: P1) 🎯 MVP

A signed-in Sunner cold-launches the app (or taps the SAA 2025 tab
from elsewhere) and immediately sees the brand keyvisual, the
"ROOT FURTHER" theme, a live countdown to event day (DD / HH / MM),
and the time / venue / livestream copy.

**Why this priority**: this is THE tab-root MVP. Without it, the App
shell has no content; every other M2+ flow uses Home as its origin
point.

**Independent Test**: launch the app with a valid Supabase session →
Home renders within 800 ms (p95) → countdown ticks every minute →
event date `26/12/2025`, venue `Âu Cơ Art Center`, and livestream
copy are visible.

**Acceptance Scenarios**:

1. **Given** the user has a valid Supabase session, **When** the app
   cold-launches, **Then** Home is the visible root view, the
   countdown shows non-negative `DD HH MM` derived from
   `eventTargetDate − now`, and the event date / venue strings are
   visible.
2. **Given** the user is on Home, **When** one minute passes, **Then**
   the `MM` (minutes) value decrements by 1 and `HH` / `DD` adjust on
   60-min / 24-hour rollovers.
3. **Given** the user is on Home and the device returns from
   background after 10 minutes, **When** Home becomes foreground,
   **Then** the countdown re-syncs to the current `eventTargetDate −
   now` (no stale value persists).
4. **Given** `eventTargetDate` has passed, **When** Home renders,
   **Then** the countdown clamps to `00 DAYS 00 HOURS 00 MINUTES`
   (no negative values), and the "Coming soon" label is hidden.
   No "Event Ended" / "Đã diễn ra" copy is shown — the design
   stays as a static zero countdown (Q1 resolved 2026-04-27).
5. **Given** the session is missing or expired on appear, **When**
   Home tries to render, **Then** the user is routed to `[iOS] Login`
   without flashing Home content (auth guard upstream of HomeViewModel).

---

### User Story 2 — Browse award categories and open a detail page (Priority: P1)

A Sunner scrolls into the Awards section, swipes the horizontal card
list to discover the 6 categories, and taps `Chi tiết` on a card to
open the corresponding award-detail screen.

**Why this priority**: discovery of the awards system is the top
business goal of Home — without it, awards pages are unreachable
from the main flow.

**Independent Test**: with seeded `public.awards` data → Awards
section renders 3 cards, swipe reveals more, tap `Chi tiết` →
correct `[iOS] Award_*` screen opens.

**Acceptance Scenarios**:

1. **Given** `public.awards` returns 3+ rows ordered by
   `display_order`, **When** Home is fully loaded, **Then** the
   Awards section shows a horizontally scrollable card list with each
   card displaying the artwork, the localised `title`, a truncated
   `description` (ellipsis when overflowing), and a `Chi tiết` CTA.
2. **Given** the user is on Home, **When** they swipe left/right on
   the awards row, **Then** the cards scroll smoothly to reveal
   adjacent categories.
3. **Given** the user taps `Chi tiết` on a card whose `kind` is
   `top_talent`, **When** the navigation completes, **Then** the
   route `AppRoute.awardDetail(kind: .topTalent)` is pushed and the
   Home VM emits a `home.award_card_tap{ kind: "top_talent" }`
   analytics event. **In M2**, this route renders the shared
   `AwardDetailPlaceholder` ("Coming soon"). **In M4**, the same
   route case is bound to `AwardDetailView(kind:)` rendering the
   real Figma frame (`[iOS] Award_Top Talent` = `c-QM3_zjkG`,
   `[iOS] Award_Top Project` = `FQoJZLkG_d`, etc.) — no nav-contract
   change required.
4. **Given** the awards fetch fails (5xx / network), **When** Home
   loads, **Then** the Awards section shows an inline retry row
   ("Không tải được — Thử lại") inside that section while the rest of
   Home (countdown, Kudos, FAB, tabs) remains usable.
5. **Given** `public.awards` returns zero rows, **When** Home loads,
   **Then** the Awards section shows the empty-state copy "Giải
   thưởng sẽ được công bố sớm" / "Awards will be announced soon" in
   place of cards.
6. **Given** the user taps the `ABOUT AWARD` hero CTA, **When** the
   action fires, **Then** Home scrolls to the `AwardsTeaser` anchor
   (same-screen scroll — no navigation).

---

### User Story 3 — See unread notifications via the bell (Priority: P1)

A Sunner sees an unread-notification dot on the bell icon when there
are pending notifications and taps the bell to open the Notifications
panel.

**Why this priority**: the bell is the only persistent affordance for
new activity (Kudos received, comments, moderation events). Without
it the user has no way to discover new events except by remembering
to open the panel manually.

**Independent Test**: seed one unread `public.notifications` row for
the user → cold-launch Home → bell shows the dot → tap → push to
`[iOS] Notifications`. Mark all read in Notifications → return to
Home → dot is gone.

**Acceptance Scenarios**:

1. **Given** the user has at least one notification with
   `read_at IS NULL` for `recipient_id = auth.uid()`, **When** Home
   appears, **Then** the bell renders an unread-dot badge.
2. **Given** the user has no unread notifications, **When** Home
   appears, **Then** the bell is shown without the dot.
3. **Given** Supabase Realtime emits a new notification while Home is
   foregrounded, **When** the event lands, **Then** the dot appears
   without requiring a refresh.
4. **Given** the unread count fetch fails on first load of the
   session, **When** Home renders, **Then** the dot is suppressed
   (do NOT show a wrong badge) and no error UI surfaces. (Mid-
   session failures preserve the last known good dot — see Edge
   Cases.)
5. **Given** the user taps the bell, **When** the navigation fires,
   **Then** `[iOS] Notifications` (`_b68CBWKl5`) is pushed.

---

### User Story 4 — Quick Kudos actions from the floating button (Priority: P2)

A Sunner uses the FAB at the bottom of Home to either compose a new
Kudo (pen icon) or jump to the Kudos feed (Sun\*Kudos `S` logo).
Per Figma `mms_6_float button` (`6885:9058`), the FAB exposes
**two distinct tap zones** within one floating element.

**Why this priority**: the FAB is the **fast path** to the two most
common Kudos actions; without it, users must drill through the
header bell or the bottom tab to reach either flow.

**Independent Test**: on Home → tap pen icon → compose screen opens.
Repeat → tap Kudos logo icon → Kudos feed opens.

**Acceptance Scenarios**:

1. **Given** the user is on Home, **When** they tap the FAB's pen
   icon, **Then** `[iOS] Sun*Kudos_Gửi lời chúc Kudos`
   (`PV7jBVZU1N`) is pushed with no recipient pre-selected.
2. **Given** the user is on Home, **When** they tap the FAB's
   Sun\*Kudos `S` logo icon, **Then** `[iOS] Sun*Kudos`
   (`fO0Kt19sZZ`) is pushed.
3. **Given** the user double-taps either FAB tap zone rapidly,
   **When** the second tap fires within 300 ms of the first OR
   while a navigation is already in flight, **Then** only ONE
   navigation occurs (debounce + in-flight guard, applied
   per-zone).
4. **Given** Home is scrolled to the bottom, **When** the user
   continues scrolling, **Then** the FAB stays pinned to its
   trailing-bottom position above the Tab Bar (does not scroll
   away).
5. **Given** the user has already navigated away to compose or
   to the Kudos feed, **When** they return to Home (Home becomes
   visible again), **Then** the FAB tap zones re-arm (in-flight
   guard cleared on Home's `onAppear`).

> **Q3 (UX simplification)**: Designer is asked to consider
> collapsing the two tap zones into a single compose-only CTA, since
> the Kudos feed is already reachable via the bottom Kudos tab AND
> the section's "Chi tiết" button — making the second FAB zone a
> redundant third entry point. Default behaviour above mirrors the
> Figma design until Q3 is resolved.

---

### User Story 5 — Switch interface language from the chip (Priority: P2)

A Sunner taps the language chip in the header, picks `Tiếng Việt` or
`Tiếng Anh` from the anchored dropdown, and Home re-renders in the
chosen language; the choice persists across launches.

**Why this priority**: bilingual support is required by the SAA
programme; the chip is the only visible language affordance on Home.

**Independent Test**: open Home in EN → tap chip → pick `Tiếng Việt`
→ awards titles, headings, CTAs re-render in VN within 250 ms →
relaunch → still VN.

**Acceptance Scenarios**:

1. **Given** the user is on Home, **When** they tap the language
   chip, **Then** the `LanguagePickerDropdown` (shared component,
   spec'd in [login.md](../../contexts/screen_specs/login.md)) is
   anchored under the chip showing `Tiếng Việt` and `Tiếng Anh`,
   with the current language pre-highlighted.
2. **Given** the dropdown is open, **When** the user picks the
   alternative language, **Then** the dropdown dismisses, the choice
   is persisted to `LocaleStore`, and every visible Home text
   element re-renders within 250 ms.
3. **Given** the user picks the *currently selected* language,
   **When** the action fires, **Then** the dropdown dismisses but
   `LocaleStore` does NOT re-emit (idempotent set, no re-render
   churn).

---

### User Story 6 — Refresh dynamic content (Priority: P2)

A Sunner pulls down at the top of Home to refresh the awards teaser,
Kudos banner, and unread-notification count.

**Why this priority**: the user has no other way to force a refresh
mid-session — without pull-to-refresh, stale data persists until app
relaunch.

**Independent Test**: change a Kudos highlight server-side → on Home,
pull down → Kudos banner updates within 1 s after refresh
indicator dismisses.

**Acceptance Scenarios**:

1. **Given** the user is at the top of Home, **When** they pull down
   beyond the gesture threshold, **Then** a system progress
   indicator appears, all "On screen load" queries (awards teaser,
   Kudos banner, unread count) re-fire, and the indicator dismisses
   on success.
2. **Given** any one query fails during refresh, **When** the
   refresh completes, **Then** the indicator dismisses, the
   succeeding sections update, and the failing section falls back
   to the same error UI as the initial-load path.

---

### User Story 7 — Open Search from the header (Priority: P3)

A Sunner taps the search icon in the header to find a Sunner / Kudos
content via the dedicated search screen.

**Why this priority**: the search destination is owned by the Kudos
cluster and not blocking M2; on Home the icon just navigates.

**Independent Test**: tap search icon → `[iOS] Sun*Kudos_Search Sunner`
opens.

**Acceptance Scenarios**:

1. **Given** the user is on Home, **When** they tap the search icon,
   **Then** `[iOS] Sun*Kudos_Search Sunner` (`3jgwke3E8O`) is pushed.

> **Open Question Q4**: Search scope (global vs Sunner-only) is owned
> by the Kudos cluster; this US is the navigation contract only.

---

### User Story 8 — Switch tabs via the bottom bar (Priority: P2)

A Sunner taps `Awards`, `Kudos`, or `Profile` to switch tabs; tapping
the active `SAA 2025` tab scrolls Home back to the top.

**Why this priority**: the tab bar is the app's primary navigation
surface; broken tabs disable the whole shell.

**Independent Test**: from Home → tap each tab → arrive at correct
root → tab indicator is highlighted on the active tab.

**Acceptance Scenarios**:

1. **Given** the user is on Home, **When** they tap the `Profile`
   tab, **Then** `[iOS] Profile bản thân` (`hSH7L8doXB`) is shown
   with the Profile tab highlighted.
2. **Given** the user is on Home, **When** they tap the `Kudos` tab,
   **Then** `[iOS] Sun*Kudos` (`fO0Kt19sZZ`) is shown with the
   Kudos tab highlighted.
3. **Given** the user is on Home, **When** they tap the `Awards`
   tab, **Then** `AppRoute.awardDetail(kind: .topTalent)` is set as
   the tab's root and the Awards tab is highlighted. In M2 this
   renders the `AwardDetailPlaceholder` ("Coming soon") consuming
   the shared `ErrorStateView`; the Back button / tab bar remain
   reachable. In M4 the same route case renders the real
   `AwardDetailView` — Awards-cluster work decides whether to
   promote the tab root to a list / pager view at that time.
4. **Given** the user is on Home and has scrolled down, **When**
   they tap the active `SAA 2025` tab, **Then** Home scrolls back
   to the top (idiomatic iOS tab-root behaviour).

---

### Edge Cases

- **Cold launch with stale countdown**: app was last opened before
  daylight-savings transition / device-clock change. Solution:
  countdown is computed from `eventTargetDate − Date()` on every
  tick, never cached.
- **Background ≥ access-token TTL**: `RestoreSessionUseCase` runs
  silently from `RootView` (M1 wiring) before Home reads any
  authenticated table — Home itself only handles the post-restore
  states (`signedIn` continue; `signedOut` route to Login).
- **Realtime channel disconnects mid-session**: fall back to a 30 s
  polling relay on `notifications` unread count; both share the same
  `ObserveUnreadNotificationsUseCase` output (last value wins).
- **Realtime channel fails to subscribe at all** (e.g. WebSocket
  blocked by the network): start polling immediately at the same
  30 s cadence; never block Home render on a Realtime handshake.
- **Bell dot retention on transient errors**: if the unread-count
  fetch fails AFTER a successful previous fetch in the same session,
  the dot retains its last known good value (do not flicker off).
  Only on the FIRST fetch of the session, a failure suppresses the
  dot (US3 AS4).
- **Awards table empty AND Kudos banner empty**: still show
  countdown + hero + tabs + FAB (Home is never blank).
- **FAB tapped while a navigation is already in flight**: ignore;
  in-flight guard is cleared when the user returns to Home (US4
  AS5). Rapid double-taps within the same arm are debounced by
  the 300 ms window documented in US4 AS3 (per-zone).
- **Push from a deep link landing on Home**: `app://home` and any
  `awards#kind` / `kudos#highlight-id` deep links resolve to Home,
  then the post-render scroll-anchor / push handler executes (deep
  link queue lives in the navigation feature, NOT here).
- **Pull-to-refresh during initial load**: refresh re-issues only the
  three home-feed queries; if initial load is still in flight, the
  newer trigger replaces it (`flatMapLatest`).
- **Realtime emits a new notification with `read_at` already set**:
  ignore (defensive — Realtime should not send already-read events).

---

## UI/UX Requirements *(from Figma)*

### Screen Components

| Component | Description | Interactions |
|-----------|-------------|--------------|
| `mms_1_header` (`6885:9057`) | Top bar: logo + language chip + search + bell | Tap chip / search / bell |
| `LanguageSwitcherChip` (`I6885:9057;88:1829`) | Shared with Login — flag + lang code + chevron | Tap → present `LanguagePickerDropdown` |
| `SearchIconButton` (`I6885:9057;88:1869`) | Search affordance | Tap → push search screen |
| `NotificationIconButton` (`I6885:9057;88:1830`) | Bell with unread-dot badge | Tap → push Notifications |
| `mms_2.1_MM_MEDIA_Logo/RootFuther` (`6885:8984`) | "ROOT FURTHER" hero wordmark | display-only |
| `CountdownTimer` (within `mms_2_content` `6885:8983`) | DD / HH / MM ticking each minute | display-only |
| `EventInfoList` (within `6885:8983`) | Time + Venue + Livestream copy | display-only |
| `mms_2.2_Button` (`6885:9026`) `ABOUT AWARD` | Primary hero CTA | Tap → scroll to AwardsTeaser |
| `mms_2.3_Button` (`6885:9027`) `ABOUT KUDOS` | Secondary hero CTA | Tap → scroll to KudosSection |
| `mms_3_note` (`6885:9028`) | "Root Further" theme paragraph | display-only |
| `mms_4_awards` (`6885:9030`) | Awards section container | container — child cards interact |
| `mms_4.1_header` (`6885:9031`) | "Sun\* Annual Awards 2025 / Hệ thống giải thưởng" | display-only |
| `mms_4.2_award list` (`6885:9032`) | Horizontal scroll of `AwardCard`s | Swipe / tap `Chi tiết` |
| `AwardCard` (×N, e.g. `6885:9033-9035`) | Per-category teaser card | Tap `Chi tiết` → push award detail |
| `mms_5_kudos` (`6885:9039`) | Kudos section container | — |
| `mms_5.1_header` (`6885:9040`) | "Phong trào ghi nhận / Sun\* Kudos" | display-only |
| `mms_5.2_mm_media_Sunkudos` (`6885:9041`) | Kudos banner image | display-only |
| `mms_5.3_Button` (`6885:9055`) `Chi tiết` (Kudos) | Kudos CTA | Tap → push Kudos feed |
| `mms_6_float button` (`6885:9058`) | FAB with two tap zones (pen + Kudos `S` logo) | Tap pen → push compose-kudo · Tap `S` → push Kudos feed |
| `mms_7_nav bar` (`6885:9056`) | 4-tab bottom bar | Tap tab |

### Navigation Flow

- **From**: app launch (with valid session) · `[iOS] Login` (post-auth) ·
  any other tab via `mms_7_nav bar`.
- **To**:
  - `[iOS] Notifications` (bell), `[iOS] Sun*Kudos_Search Sunner`
    (search), `LanguagePickerDropdown` (chip).
  - `AppRoute.awardDetail(kind:)` — covers `c-QM3_zjkG`,
    `FQoJZLkG_d`, `QQvsfK3yaK`, plus the remaining 3 award `kind`s
    as M4 swaps in their real detail views. **In M2** every
    `awardDetail(kind:)` route renders the shared
    `AwardDetailPlaceholder`. Triggered by AwardCard "Chi tiết" or
    Awards tab.
  - `[iOS] Sun*Kudos` (`fO0Kt19sZZ`) — Kudos feed CTA & tab.
  - `[iOS] Sun*Kudos_Gửi lời chúc Kudos` (`PV7jBVZU1N`) — FAB.
  - `[iOS] Profile bản thân` (`hSH7L8doXB`) — Profile tab.
- **Same-screen anchors**: `ABOUT AWARD` / `ABOUT KUDOS` scroll the
  `ScrollView` to the `mms_4_awards` / `mms_5_kudos` Y-anchors.
- **Auth guard**: missing/expired session redirects upstream (in
  `AuthRouterBinder` / `RootView`); Home itself does NOT need to
  re-check session on every appear.

### Behavioral Requirements (iOS / HIG — Principle II)

- **Device support**: iPhone portrait primary; iPad and landscape
  MUST remain functional (no clipping, no broken interactions).
  Concrete responsive breakpoints are an implementation concern
  fetched at `/momorph.implement-ui` time.
- **Dynamic Type**: every text element MUST scale through to
  `accessibility5` without truncation; the awards horizontal row
  reflows to vertical at the largest sizes — exact threshold is
  an implementation concern.
- **Reduced Motion**: when `UIAccessibility.isReduceMotionEnabled`
  is true, the countdown digit transitions are static (no
  animation); the refresh indicator uses the system default.
- **Accessibility (MANDATORY)**:
  - `accessibilityLabel` on header icons (chip / search / bell)
    per [home.md § Accessibility](../../contexts/screen_specs/home.md).
  - Bell label: `"Thông báo. Có \(n) thông báo chưa đọc."` /
    `"Có thông báo mới."` / `"Thông báo. Không có mới."`.
  - Award card combined label:
    `"\(awardName). \(awardTagline). Nhấn để xem chi tiết."`
  - FAB pen label `"Viết Kudo"`, hint `"Ghi nhận đồng nghiệp"`;
    FAB Kudos-logo label `"Mở Sun*Kudos"` (see US4).
  - Countdown announced as a live region every MINUTE (not every
    second) to avoid VoiceOver noise.
  - Touch targets MUST meet HIG minimum.
  - VoiceOver focus order: `Header (logo → language chip → search
    → bell)` → `Hero (countdown → event info → ABOUT AWARD →
    ABOUT KUDOS)` → `Awards header → cards` → `Kudos section →
    Chi tiết` → `FAB` → `Tab bar`.
- **Localization**: every user-facing string MUST be a key in
  `Localizable.xcstrings`. New keys in this milestone:
  `home.comingSoon`, `home.countdown.days`, `home.countdown.hours`,
  `home.countdown.minutes`, `home.event.time`, `home.event.place`,
  `home.event.livestream`, `home.cta.aboutAward`,
  `home.cta.aboutKudos`, `home.theme.note`, `home.awards.title`,
  `home.awards.subtitle`, `home.awards.empty`, `home.awards.error`,
  `home.kudos.category`, `home.kudos.title`, `home.kudos.note`,
  `home.kudos.detailButton`, `home.kudos.newBadge`,
  `home.fab.compose.label`, `home.fab.compose.hint`,
  `home.fab.feed.label`, `tab.saa`, `tab.awards`, `tab.kudos`, `tab.profile`,
  `home.bell.unread.singular`, `home.bell.unread.plural`,
  `home.bell.empty`, `awards.placeholder.title`,
  `awards.placeholder.subtitle`, `awards.placeholder.primaryButton`.
  The three `awards.placeholder.*` keys may collapse onto the
  existing M1 `notFound.*` keys if Design approves identical
  "Coming soon" copy. (No `home.event.ended` key — Q1 resolved to
  clamp at zero with no extra copy.)

---

## Component Behavior

(Each interactive component lists its Node ID — these are how the
implementer locates exact elements via `query_section`.)

### Header (`mms_1_header` — `6885:9057`)

| Component | Node ID | Behaviour |
|-----------|---------|-----------|
| `LanguageSwitcherChip` | `I6885:9057;88:1829` | **Interaction**: tap. **Effect**: present `LanguagePickerDropdown` anchored under chip. **State**: enabled always. **Persistence**: shared with Login, behaviour spec'd in [login.md](../../contexts/screen_specs/login.md). |
| `SearchIconButton` | `I6885:9057;88:1869` | **Interaction**: tap. **Effect**: push `[iOS] Sun*Kudos_Search Sunner`. **Validation**: none. **Accessibility**: `.isButton` trait; label `"Tìm kiếm"` / `"Search"`. |
| `NotificationIconButton` | `I6885:9057;88:1830` | **Interaction**: tap. **Effect**: push `[iOS] Notifications`. **State**: dot rendered when `unreadCount > 0`. **Realtime**: subscribes to Supabase Realtime on `notifications` for live updates. **Accessibility**: announces unread count. |

### Hero (`mms_2_content` — `6885:8983`)

| Component | Node ID | Behaviour |
|-----------|---------|-----------|
| `CountdownTimer` | inside `6885:8983` | **Interaction**: none (display). **Tick**: every 1 s recompute from `eventTargetDate − now`; UI updates per minute (announce per minute). **Zero state** (`eventTargetDate ≤ now`): values are clamped to `0 / 0 / 0`; the "Coming soon" label is hidden; no "Event Ended" copy is shown — the layout is identical to the live countdown, just frozen at zero (Q1). |
| `ABOUT AWARD` button | `6885:9026` | **Interaction**: tap. **Effect**: scroll to `AwardsTeaser` Y anchor (same screen). **State**: always enabled. |
| `ABOUT KUDOS` button | `6885:9027` | **Interaction**: tap. **Effect**: scroll to `KudosSection` Y anchor. **State**: always enabled. |

### Awards section (`mms_4_awards` — `6885:9030`)

| Component | Node ID | Behaviour |
|-----------|---------|-----------|
| `AwardCardsRow` | `6885:9032` | **Interaction**: horizontal pan / swipe → scrolls cards. **State**: loading skeleton (3 placeholder cards) → success (≥1 card) → empty ("Giải thưởng sẽ được công bố sớm") → error (inline retry row). **Lazy**: cards beyond viewport are recycled. |
| `AwardCard` | `6885:9033-9035` (and per-`kind` siblings) | **Interaction**: tap `Chi tiết` button. **Effect**: push `AppRoute.awardDetail(kind:)` keyed by `awards.kind`. **M2**: route renders `AwardDetailPlaceholder` ("Coming soon"); **M4**: route renders the real `AwardDetailView(kind:)`. **Validation**: `description` is truncated with ellipsis when overflowing the card width; full text only shown on detail. |

### Kudos section (`mms_5_kudos` — `6885:9039`)

| Component | Node ID | Behaviour |
|-----------|---------|-----------|
| `KudosBanner` | `6885:9041` | **Interaction**: none (display image). **Fallback**: when image fails to load, show a coloured-block placeholder with the Kudos logo + "KUDOS" text — never block page render. |
| `Chi tiết (Kudos)` | `6885:9055` | **Interaction**: tap. **Effect**: push `[iOS] Sun*Kudos` (Kudos feed). **State**: always enabled. |

### FAB (`mms_6_float button` — `6885:9058`)

Two tap zones within one floating element, per design.

| Tap zone | Behaviour |
|----------|-----------|
| Pen icon | **Interaction**: tap. **Effect**: push `[iOS] Sun*Kudos_Gửi lời chúc Kudos` (`PV7jBVZU1N`). **Debounce**: 300 ms + in-flight guard (US4 AS3). **Accessibility**: label `"Viết Kudo"`, hint `"Ghi nhận đồng nghiệp"`. |
| Sun\*Kudos `S` logo icon | **Interaction**: tap. **Effect**: push `[iOS] Sun*Kudos` (`fO0Kt19sZZ`) — same destination as the Kudos tab. **Debounce**: 300 ms + in-flight guard (per-zone). **Accessibility**: label `"Mở Sun*Kudos"`. |

**Position**: pinned trailing-bottom, layered above the Tab Bar; does
not scroll with content. Q3 below tracks a proposed UX simplification.

### Bottom tab bar (`mms_7_nav bar` — `6885:9056`)

Generic tap behaviour applies to every tab item:

- **Inactive → tap** : `TabRouter.selectedTab` is updated; the
  destination view becomes visible; the tapped tab is highlighted;
  the previously-active tab returns to its inactive state.
- **Active → re-tap** : the destination's primary `ScrollView`
  scrolls to its `top` anchor (idiomatic iOS); the destination
  view is NOT remounted; transient state (forms, search input)
  is preserved.

| Tab | Node ID | Destination | Notes |
|-----|---------|-------------|-------|
| SAA 2025 | `I6885:9056;75:2009` | Home (this screen) | Default-active when the user lands post-auth. |
| Awards | `I6885:9056;75:2012` | `AwardDetailPlaceholder` (M2) → `AwardDetailView(kind: .topTalent)` (M4) | Tab pushes `AppRoute.awardDetail(kind: .topTalent)`; M4 may promote the tab root to a list/pager view (per Q2 resolution). |
| Kudos | `I6885:9056;75:2015` | `[iOS] Sun*Kudos` (`fO0Kt19sZZ`) | Kudos feed. |
| Profile | `I6885:9056;75:2018` | `[iOS] Profile bản thân` (`hSH7L8doXB`) | Current user's profile. |

---

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST render Home as the visible root view within
  800 ms (p95) of cold launch when a valid session exists in the
  Keychain.
- **FR-002**: System MUST display a real-time countdown to
  `AppConfig.eventTargetDate`, updating at least every minute. When
  the target has passed the countdown values clamp to
  `0 / 0 / 0` (no negatives) and the "Coming soon" label is hidden.
- **FR-003**: Users MUST be able to browse the awards teaser
  horizontally and open any award's detail screen by tapping
  `Chi tiết`.
- **FR-004**: System MUST surface unread-notification status with a
  bell-dot badge that reflects `count(notifications) WHERE
  recipient_id = auth.uid() AND read_at IS NULL`, updating in real
  time when the user is foregrounded.
- **FR-005**: Users MUST be able to (a) compose a new Kudo via the
  FAB's pen tap zone and (b) open the Kudos feed via the FAB's
  Kudos-logo tap zone, each in a single tap. Rapid double-taps
  MUST NOT spawn duplicate navigations on either zone.
- **FR-006**: Users MUST be able to switch interface language from
  the chip; selection persists across launches via `LocaleStore`.
- **FR-007**: Users MUST be able to pull-to-refresh; refreshing
  re-fires the awards / kudos-banner / unread-count queries
  concurrently.
- **FR-008**: System MUST allow tab switching between
  `SAA 2025` / `Awards` / `Kudos` / `Profile`. Tapping the active
  `SAA 2025` tab MUST scroll Home back to the top.
- **FR-009**: System MUST gracefully degrade when sub-feature data
  fails to load (Awards → inline retry row; Kudos banner → silent
  hide; unread count → suppress dot). Home MUST NEVER fail to
  render.
- **FR-010**: System MUST scroll to the appropriate section anchor
  when the user taps `ABOUT AWARD` / `ABOUT KUDOS`.

### Technical Requirements

- **TR-001 (Performance)**: Home cold-launch first-content render
  ≤ 800 ms p95 on iPhone 12+ with cached session (matches
  `SC-AUTH-1`'s tail; Home extends the same window).
- **TR-002 (Reactive boundaries — Principle III)**: `HomeViewModel`
  exposes inputs/outputs as Rx types only (signature in
  [home.md § State Management](../../contexts/screen_specs/home.md#state-management));
  `DisposeBag` lives on the VM; the View consumes via
  `HomeStateAdapter: ObservableObject`.
- **TR-003 (Supabase RLS — Principle V)**: every authenticated query
  uses the policies in §Supabase Dependencies. Anon-only access is
  forbidden; reads requiring auth use `auth.uid() IS NOT NULL` at
  minimum, narrower per-table policies where applicable.
- **TR-004 (Realtime)**: unread-notification subscription uses a
  Supabase Realtime channel filtered to
  `recipient_id = auth.uid()`; client falls back to 30 s polling
  if the channel disconnects.
- **TR-005 (Offline / error)**: every section has a documented
  empty / error / loading state (FR-009); no spinner ever blocks
  the entire screen.
- **TR-006 (Logging — Principle V)**: never interpolate `auth.uid()`,
  `recipient_id`, full email, or notification `payload` into
  `Logger.*` calls; only event types / counts / `award.kind` /
  `notification.type` are loggable.
- **TR-007 (Analytics)**: events listed in
  [home.md § Analytics](../../contexts/screen_specs/home.md) MUST
  fire with NO PII (no user_id, no email, no token, no full Kudos
  body); only `locale`, `unread_count_bucket` (`0` / `1-5` / `6+`),
  `award.kind`, `from`/`to` tab IDs.

### Key Entities

- **`EventSchedule`** *(local)*: `targetDate: Date`, `place: String`,
  `liveStreamURL: URL?`. Sourced from `AppConfig` (xcconfig). Not
  fetched.
- **`AwardTeaser`**: `kind: AwardKind` (PK), `titleVI: String`,
  `titleEN: String`, `descriptionVI: String`, `descriptionEN: String`,
  `artworkAssetKey: String`, `displayOrder: Int`. Maps from
  `public.awards`.
- **`KudosHighlight`** *(M2 placeholder; full shape in Kudos cluster)*:
  `id: UUID`, `bannerImageURL: URL?`. Sourced from a
  `kudos_highlights` view (TBC during Kudos cluster) — for M2 the
  banner uses the bundled image asset; the dynamic banner can land
  in M4.
- **`Notification`** *(typed; full taxonomy in Notifications spec)*:
  `id: UUID`, `recipientID: UUID`, `type: NotificationType`,
  `payload: JSON`, `readAt: Date?`, `createdAt: Date`. Maps from
  `public.notifications`.

---

## Supabase Dependencies

### Tables / Views

| Table | Access | RLS policy required | Status |
|-------|--------|---------------------|--------|
| `public.awards` | SELECT (read-only on Home) | **authenticated read**: `using (auth.uid() IS NOT NULL)` (Q5 resolved 2026-04-27) | Exists (migration 0025); RLS policy must be applied on staging before PR-M2.3 |
| `public.notifications` | SELECT (head-count for the dot) | owner-only read: `using (recipient_id = auth.uid())` | Exists (migration 0024) |
| `public.kudos_highlights` *(TBC name)* | SELECT (banner) | authenticated read: `using (auth.uid() IS NOT NULL)` | New (M4 — placeholder for M2) |

### Storage

| Bucket | Access pattern | Policy | Status |
|--------|----------------|--------|--------|
| `award-artwork` | read public | `using (true)` | New (M2 prerequisite — TBC during awards-asset prep) |

### Edge Functions

| Function | Trigger | Why service-role needed | Status |
|----------|---------|-------------------------|--------|
| (none) | — | — | — |

### Realtime channels

| Channel | Filter | Why | Status |
|---------|--------|-----|--------|
| `public.notifications` | `recipient_id=eq.${auth.uid()}` | Live unread badge | Exists (RLS replicates SELECT policy) |

---

## API Requirements (Predicted)

All endpoint shapes are formalised in
[`api-docs.yaml`](../../contexts/api-docs.yaml).

| Endpoint / SDK call | Method | Purpose | Triggered by |
|---------------------|--------|---------|--------------|
| `supabase.from("awards").select().order("display_order").limit(6)` | GET | Awards teaser content | Home appear / refresh |
| `supabase.from("notifications").select("id", count: "exact", head: true).eq("recipient_id", uid).is("read_at", nil)` | HEAD | Unread count for the dot | Home appear / refresh |
| `supabase.from("kudos_highlights").select().limit(1)` *(M4 hook — M2 falls back to bundled asset)* | GET | Kudos banner (dynamic) | Home appear / refresh |
| Realtime subscribe `public.notifications` | WS | Live dot updates | `viewAppeared` |
| `AppConfig.eventTargetDate` (local) | — | Countdown source | Home tick |
| `AppConfig.eventPlace` / `liveStreamURL` (local) | — | Event info copy | Home appear |

**Notes**:
- Unread count uses `head: true` so we never download row contents
  just to count them (Principle V — Don't leak content).
- The countdown does NOT call any backend. The target date is bundled
  per environment (`Config/{Dev,Staging,Prod}.xcconfig`).
- Awards / kudos-highlight queries are RLS-protected; failures degrade
  per FR-009.

---

## State Management

### Local — `HomeViewModel` (Principle III)

```swift
protocol HomeViewModel {
    // Inputs
    var viewAppeared: PublishRelay<Void> { get }
    var pullToRefresh: PublishRelay<Void> { get }
    var languageTapped: PublishRelay<Void> { get }
    var languageSelected: PublishRelay<AppLanguage> { get }
    var searchTapped: PublishRelay<Void> { get }
    var notificationsTapped: PublishRelay<Void> { get }
    var aboutAwardTapped: PublishRelay<Void> { get }   // scroll anchor
    var aboutKudosTapped: PublishRelay<Void> { get }   // scroll anchor
    var awardCardTapped: PublishRelay<AwardKind> { get }
    var kudosDetailTapped: PublishRelay<Void> { get }
    var fabComposeTapped: PublishRelay<Void> { get }    // FAB pen icon
    var fabKudosFeedTapped: PublishRelay<Void> { get }  // FAB Sun*Kudos `S` icon
    var tabTapped: PublishRelay<AppTab> { get }
    var activeTabReTapped: PublishRelay<Void> { get }   // SAA-tap-while-active

    // Outputs
    var isRefreshing: Driver<Bool> { get }
    var countdown: Driver<CountdownVM> { get }
    var awards: Driver<AwardsTeaserState> { get }
    var kudosBanner: Driver<KudosBannerState> { get }
    var hasUnreadNotifications: Driver<Bool> { get }
    var selectedLanguage: Driver<AppLanguage> { get }
    var navigate: Signal<AppRoute> { get }
    var presentLanguagePicker: Signal<Void> { get }
    var scrollTo: Signal<HomeAnchor> { get }
    var errorMessage: Signal<String> { get }
}

enum AwardsTeaserState { case loading, loaded([AwardTeaser]), empty, error }
enum KudosBannerState  { case loading, loaded(KudosHighlight), empty }
enum HomeAnchor        { case top, awards, kudos }
```

Outputs MUST use `Driver` / `Signal`. Errors are materialised into
the per-section state enums above; a generic `errorMessage` is reserved
for cross-cutting issues (e.g. session vanished mid-session).

### Global

| Store | Owns | Producers | Consumers |
|-------|------|-----------|-----------|
| `AuthStore` | `AuthState` | M1 auth pipeline | `HomeViewModel` (read-only), every screen |
| `LocaleStore` | `currentLanguage` | `LanguagePickerDropdown` selection | All localised strings |
| `TabRouter` (NEW M2) | `selectedTab: AppTab` | `BottomTabBar` | `RootView` |
| `NotificationStore` (NEW M2) | `unreadCount: Int` (and Realtime subscription handle) | `ObserveUnreadNotificationsUseCase` | `HomeViewModel`, future Notifications screen |

### Cache / invalidation

- Awards teaser: cached in-memory by `HomeViewModel` between refreshes;
  invalidated by `pullToRefresh` and `viewAppeared` after `AppActive`.
- Kudos banner: same.
- Unread count: never cached — sourced from Realtime + initial
  HEAD query.
- `LocaleStore.currentLanguage`: persisted in `UserDefaults`.

### Optimistic updates

- **None** on Home — all surfaces are read-only; every mutation
  happens on downstream screens (Notifications mark-read, Kudos
  compose).

---

## Constitution alignment

Cross-checked against
[.momorph/constitution.md](../../constitution.md):

- **I. Clean Architecture**: Home Domain has no Supabase imports;
  ViewModel exposes Rx I/O; the SwiftUI bridge is the only place
  `import Combine` is allowed.
- **II. SwiftUI-First & HIG**: SwiftUI implementation; Dynamic Type
  through `accessibility5`; localised strings; HIG-minimum touch
  targets; VoiceOver coverage per [home.md § Accessibility](../../contexts/screen_specs/home.md).
  Visual tokens (colors, typography, spacing) are extracted from
  Figma at implementation time per the post-M1 process amendment.
- **III. Reactive Data Flow with RxSwift**: countdown uses
  `Observable<Int>.interval(.seconds(1), …)`; unread-count uses
  Realtime → `BehaviorRelay`; pull-to-refresh uses `flatMapLatest`.
  `subscribe(on:)` / `observe(on:)` set explicitly at SDK
  boundaries.
- **IV. Test-First**: RxTest scenarios for every US acceptance
  criterion are written **before** the corresponding ViewModel
  impl; XCUITest for cold-launch + countdown + tab-switch is a
  merge gate.
- **V. Secure-by-Default**: every table touched is RLS-policied;
  unread count uses `head: true`; logs use `.private` interpolation
  for any user identifier; analytics carry no PII.

---

## Success Criteria *(mandatory)*

| ID | Metric | Target |
|----|--------|--------|
| SC-HOME-1 | Cold-launch time-to-first-paint with cached session | < 800 ms (p95) |
| SC-HOME-2 | Awards teaser data fetched + rendered | < 1.2 s (p95) on a stable network |
| SC-HOME-3 | Bell-dot accuracy: false-negative rate (dot OFF when unread > 0) | < 0.5 % over 7 days |
| SC-HOME-4 | Pull-to-refresh round trip | < 1.5 s (p95) |
| SC-HOME-5 | Crash-free sessions on Home | ≥ 99.9 % |
| SC-HOME-6 | Tab-switch latency | < 100 ms (p95) |

---

## Out of Scope

- **Awards detail screens** (`[iOS] Award_*`) — Wave 4 swaps the
  `AwardDetailPlaceholder` for the real detail views.
- **Kudos feed and compose flows** — Wave 4 (M4).
- **Notifications inbox content** — sibling spec (Notifications, M2).
- **Search results UI** — Wave 5 (Kudos cluster).
- **Profile content** — Wave 3 (M3).
- **Promotion of the Awards tab to a list/pager root** — M4 may
  promote it; M2 ships the placeholder behind the
  `awardDetail(kind: .topTalent)` route.
- **Live event mode** (post 26/12/2025 features such as live voting
  / streaming overlay) — explicitly out of M2.

---

## Dependencies

- [x] Constitution document exists ([.momorph/constitution.md](../../constitution.md))
- [x] M1 (Auth) merged — Home depends on `AuthRouterBinder`,
      `AuthStore`, `LocaleStore`, `LanguageSwitcherChip`,
      `LanguagePickerDropdown`.
- [x] Database schema applied — `public.awards`, `public.notifications`,
      and notification taxonomy exist (migrations 0024 / 0025).
- [x] API contract defined ([api-docs.yaml](../../contexts/api-docs.yaml)).
- [x] Screen flow documented ([home.md](../../contexts/screen_specs/home.md),
      [SCREENFLOW.md](../../contexts/SCREENFLOW.md)).
- [ ] `AppConfig.eventTargetDate`, `eventPlace`, `liveStreamURL`
      values populated in `Config/{Dev,Staging,Prod}.xcconfig`
      (already present in M1 — verify values current).
- [ ] Awards artwork delivery confirmed: with Q5 resolved to
      authenticated-only RLS, the default direction (Q6) is
      **bundled assets** in `Assets.xcassets/awards/` keyed by
      `awards.artwork_asset_key` — no public Storage bucket needed.
      If Q6 ever flips back to Storage, it MUST be a private bucket
      with signed-URL access (not public-read).
- [ ] Awards rows seeded in `public.awards` for staging (6 rows).
- [ ] `kudos_highlights` view defined (M4 prerequisite — M2 may ship
      with a bundled fallback per **Q7**).
- [ ] Realtime RLS rules verified for `public.notifications`
      (replicates SELECT policy on the WS channel).

---

## Open Questions

| # | Question | Why it matters | Owner |
|---|----------|----------------|-------|
| ~~Q1~~ | ~~Final copy for "Event Ended" / "Đã diễn ra" zero-state?~~ **RESOLVED 2026-04-27**: No "Event Ended" frame. When `eventTargetDate ≤ now`, the countdown values clamp to `0 / 0 / 0` and the "Coming soon" label is hidden — the rest of the layout (DAYS / HOURS / MINUTES labels, event-info copy, hero, CTAs) stays identical. Localisation key `home.event.ended` is NOT created. | Decided | Design + PM |
| ~~Q2~~ | ~~What is the `Awards` tab root destination?~~ **RESOLVED 2026-04-27**: Both the `AwardCard` "Chi tiết" tap AND the Awards tab tap navigate to the SAME `AwardDetailPlaceholder` for M2 (a "Coming soon" screen consuming the shared `ErrorStateView`). The placeholder is wired to a new `AppRoute.awardDetail(kind: AwardKind)` case — Awards tab defaults to `.topTalent`. M4 swaps the placeholder for the real `AwardDetailView` against the same route case (no nav-contract change). M4 also decides whether the Awards tab graduates to a list/pager root. | Decided | Tech lead + PM |
| Q3 | Spec defaults to the Figma 2-tap-zone FAB (pen → compose, `S` → Kudos feed). Engineering proposes collapsing to a single compose-only CTA since the Kudos feed is already reachable via the bottom Kudos tab AND the section's "Chi tiết" button. Approve simplification? | Affects analytics events (`home.fab.compose_tap` only vs both zones) and accessibility labels | Design |
| Q4 | Search scope: global (Sunner + Kudos) vs Sunner-only? | Owned by Kudos cluster; impacts the search result view, not Home | PM |
| ~~Q5~~ | ~~`awards.public_read = true` OR `auth.uid() IS NOT NULL`?~~ **RESOLVED 2026-04-27**: **Option B — authenticated read only**. Final policy: `CREATE POLICY awards_authenticated_read ON public.awards FOR SELECT USING (auth.uid() IS NOT NULL);`. Anonymous / anon-key clients receive 403 on `from("awards").select()`. Aligns with Constitution V (secure-by-default) and matches every other authenticated-app surface. | Decided | Tech lead + Security |
| Q6 | Award artwork delivery: bundled assets in `Assets.xcassets/awards/` (default, consistent with Q5=B) OR a **private** Supabase Storage bucket with signed-URL access? **Public Storage is no longer an option** after Q5=B. | Bundled gives offline rendering + zero broken-image risk; private Storage allows late edits but requires signed-URL plumbing | Design + Tech lead |
| Q7 | M2 Kudos banner: bundled image asset OR a dynamic single-row `kudos_highlights` view? | Defines whether M4 must ship before Home can show a "real" Kudos banner | PM |

---

## Notes

- **Shared infrastructure introduced/consumed in this milestone**:
  `HomeHeader` (organism, Home-only), `BottomTabBar` (organism,
  app-wide), `TabRouter` + `AppTab` (Domain — M2 introduces),
  `NotificationStore` + `ObserveUnreadNotificationsUseCase`,
  `FetchHomeFeedUseCase` (aggregates awards / kudos-banner / unread
  count).
- **Languages**: Home re-renders immediately on language change via
  the `LocaleStore` Rx output; no network call (all strings bundled).
- **Reduced motion**: when `UIAccessibility.isReduceMotionEnabled`
  is true, countdown digit transitions are static (no animation);
  the refresh indicator falls back to the system default, which
  honours the same setting automatically. Source of truth:
  §Behavioral Requirements above.
- **Tab-bar persistence**: `BottomTabBar` is a shared organism owned
  by `RootView`. Home does NOT manage the tab bar — it just
  publishes `tabTapped` and `activeTabReTapped` events.
- **M4 handoff seam (Awards cluster)**: M2 introduces a new
  `AppRoute.awardDetail(kind: AwardKind)` case in
  [`AppRoute.swift`](../../../AIDD-SAA-2025/Presentation/Shared/Navigation/AppRoute.swift)
  and binds it to `AwardDetailPlaceholder` (consuming the existing
  `ErrorStateView` from M1). M4 swaps the binding to
  `AwardDetailView(kind:)` against the same case — no consumer
  needs to change. If M4 also promotes the Awards tab to a
  list/pager view, that is a separate `AppRoute.awardsList` case
  (or similar); the Awards tab simply re-points at the new case
  with no changes here.
- **Visual tokens for Home** (colors, typography, spacing,
  component dimensions) are deliberately NOT in this spec. They
  are extracted from Figma at `/momorph.implement-ui` time and
  written to a screen-local visual-style document, per the post-M1
  process amendment (Constitution § II).
