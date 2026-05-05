<!--
SYNC IMPACT REPORT
==================
Version change: 1.0.0 → 1.0.1
Bump rationale: PATCH. No principle meaning or governance rule changed — this
                revision only propagates principle wording into the dependent
                templates and guideline documents (consistency alignment), and
                records that propagation in this Sync Impact Report.

Modified principles: None.
Added principles: None.
Added sections: None.
Removed sections: None.

Templates requiring updates:
  - .momorph/templates/plan-template.md             ✅ updated — Technical Context
    pinned to Swift/SwiftUI/RxSwift/Supabase; Constitution Compliance Check now
    cites Principles I–V by name; Architecture Decisions rewritten around
    Presentation/Domain/Data layering; Source Code layout swapped to Clean
    Architecture folder tree; Integration Testing Strategy reframed around Rx +
    RLS + accessibility.
  - .momorph/templates/spec-template.md             ✅ updated — Visual Requirements
    now enumerate HIG mandates (Dynamic Type, Dark mode, VoiceOver, 44pt, i18n);
    Technical Requirements call out Keychain, RLS, reactive boundaries; Supabase
    Dependencies section replaced the generic "API Dependencies" table.
  - .momorph/templates/tasks-template.md            ✅ updated — Phases reorganised
    into Setup → Foundation (RLS + DI) → Domain/Data/Presentation/UI tests per
    user story; explicit `(TDD)` markers on test tasks; added "Security Review
    Gate" checklist tied to Principle V.
  - .momorph/guidelines/frontend.md                 ✅ updated — full rewrite for
    SwiftUI + RxSwift + HIG + accessibility + DI + navigation + testing.
  - .momorph/guidelines/backend.md                  ✅ updated — full rewrite for
    Supabase (schema + migrations + RLS + iOS data access + Auth + Edge Functions
    + secrets + observability + testing).
  - AGENTS.md                                       ✅ no change required.

Follow-up TODOs (carried over from v1.0.0, still deferred):
  - TODO(OWNER): Confirm the product owner / tech lead responsible for ratifying
    constitution amendments.
  - TODO(iOS_DEPLOYMENT_TARGET): Confirm the minimum supported iOS version
    (assumed iOS 17+ pending confirmation, aligning with modern SwiftUI APIs).
  - TODO(SUPABASE_REGION): Record the Supabase project region and data-residency
    requirements once provisioned.
-->

# AIDD-SAA-2025 Constitution

## Core Principles

### I. Clean Architecture & Modular Source Organization

The application MUST be layered into strictly separated concerns: **Presentation**
(SwiftUI Views + ViewModels), **Domain** (Use Cases + Entities + Repository
protocols), and **Data** (Repository implementations + Supabase data sources +
DTOs). Dependencies MUST point inward only: Presentation depends on Domain;
Data depends on Domain; Domain depends on nothing outside the Swift standard
library. Source folders MUST mirror this layering (e.g. `Presentation/`,
`Domain/`, `Data/`, plus `Core/` for cross-cutting utilities). A file SHOULD
expose a single type; files SHOULD remain under ~300 lines. Dead code, unused
imports, and commented-out blocks MUST be removed before merge.

**Rationale**: Strict layering keeps the UI swappable, makes business rules
testable without a simulator, and contains Supabase-specific concerns in one
replaceable module.

### II. SwiftUI-First & Human Interface Guidelines Compliance

All new screens MUST be built with SwiftUI. UIKit is permitted only when SwiftUI
lacks a capability (e.g. advanced camera control) and MUST be wrapped behind a
`UIViewRepresentable`/`UIViewControllerRepresentable` boundary. Every screen
MUST conform to Apple's Human Interface Guidelines: system-standard navigation,
typography via Dynamic Type, semantic colors that respect Light/Dark mode, safe
areas, and SF Symbols for iconography where applicable. Accessibility is NOT
optional: every interactive element MUST have an accessibility label, VoiceOver
MUST be verified, and touch targets MUST meet the 44×44 pt minimum.
Localization-ready strings MUST flow through `String(localized:)` or
`.strings`/`.stringsdict` catalogs — no hard-coded user-facing English.

**Rationale**: HIG compliance is both a quality bar and an App Store submission
requirement; accessibility-first design prevents costly retrofits.

**No design-fidelity placeholders survive merge.** SF Symbols, system colors
(`Color(.systemBackground)`, `Color.accentColor`, …), and system fonts as
stand-ins for branded assets are acceptable ONLY when (1) the Figma design
itself uses them, or (2) the screen's `spec.md` explicitly approves a
placeholder phase with a tracked TODO. Any UI that ships with
"placeholder until X lands" is incomplete by definition — the asset
download / token extraction MUST be a hard prerequisite of the
View-build task, not a deferred follow-up. A `design-style.md` for each
screen (extracted from Figma at `/momorph.specify` time via
`query_section` / `list_media_nodes` / `get_node_context`) is the
canonical source for colors, typography, spacing, and asset role hints,
and MUST exist before `Build *View` tasks begin.

**Visual parity gate (per UI phase, BEFORE the phase is marked done)**:
1. Render the new/changed screen on simulator (iPhone 17, light + dark).
2. `xcrun simctl io booted screenshot` and place side-by-side with the
   Figma frame export.
3. List every delta. Each delta MUST be either fixed in code OR ticketed
   with a written rationale (asset blocked on designer, copy pending PM,
   etc.) — never silently shipped.

**Deferral discipline**: a task may only be marked `⚠️ deferred` when its
`Blocker:` field declares one of `external-creds`, `external-infra`,
`pm-decision`. Anything else (e.g. "needs MCP access", "I haven't written
it yet") is not a valid deferral and MUST block the surrounding phase
until completed.

### III. Reactive Data Flow with RxSwift (NON-NEGOTIABLE)

Asynchronous work crossing layer boundaries (network, database, long-running
computations, user-driven streams) MUST be modelled as RxSwift `Observable`,
`Single`, `Completable`, or `Maybe`. ViewModels MUST expose inputs and outputs
as Rx types and MUST NOT leak Rx types into SwiftUI Views — a thin adapter
(e.g. `@Published` bridge or `RxSwiftUI`-style binding) converts streams to
SwiftUI state at the View boundary. Subscriptions MUST be stored in a
`DisposeBag` owned by the ViewModel. Side effects (navigation, analytics,
persistence writes) MUST be triggered via explicit operators (`do(onNext:)`,
`flatMap`) — never hidden inside Views. `subscribe(on:)` / `observe(on:)` MUST
be set explicitly at the boundary between layers; relying on the caller's
thread is forbidden.

**Rationale**: A single reactive model for async eliminates the Combine/async-
await/closure mix that fragments testability and makes retry, cancellation, and
back-pressure reasoning ad-hoc.

**Default actor isolation**: the project sets
`SWIFT_DEFAULT_ACTOR_ISOLATION = nonisolated`. RxSwift schedulers fire on any
queue, so Domain / Data / Core types MUST be free of implicit `@MainActor`
inference; Xcode 17's default of `MainActor` here would force every Rx
subscriber boundary into a static-isolation violation. Concretely:

- Domain entities, use cases, repositories, data sources, stores, the DI
  container — all written without an actor annotation, picking up
  `nonisolated` automatically.
- The SwiftUI bridge layer is the only `@MainActor` surface: `View` bodies
  get it from the `View` protocol; `*StateAdapter: ObservableObject`
  classes get it transitively via `@StateObject` / `@Published`.
- A new class that genuinely needs MainActor (e.g. an SwiftUI-only
  `ObservableObject` with no Rx subscriptions) MUST annotate `@MainActor`
  explicitly — do not rely on the default and do not silently flip the
  project setting back. Decisions to widen the MainActor surface
  follow the Governance amendment process (§Governance).

### IV. Test-First Discipline (NON-NEGOTIABLE)

New Domain logic (Use Cases, entity invariants) MUST be covered by XCTest unit
tests written **before** the implementation, following Red → Green → Refactor.
Rx-based ViewModels MUST be tested using `RxTest`/`RxBlocking` with a
`TestScheduler` — no real clock, no real network. Data-layer repositories MUST
have integration tests running against a disposable Supabase test project or a
local mock HTTP layer; production credentials MUST NOT appear in tests. UI
regression MUST be covered by XCUITest for each P1 user story. A pull request
that reduces overall line coverage of the Domain layer below its prior level
MUST NOT merge without an explicit exemption recorded in the PR description.

**Rationale**: The team's speed on later features depends on a safety net
established from day one; retroactive testing on SwiftUI + Rx code is
materially more expensive than writing tests first.

### V. Secure-by-Default (OWASP Secure Coding Practices)

The app MUST follow the OWASP Mobile Application Security Verification Standard
(MASVS) at Level 1 as a minimum. Specifically:

- **Secrets**: API keys, Supabase anon/service keys, and tokens MUST NOT be
  committed to the repository. Runtime secrets MUST be read from `.xcconfig` /
  environment-injected build settings and rotated when leaked. The Supabase
  **service-role key MUST NEVER ship in the iOS binary** — only the anon key.
- **Authentication & authorization**: Auth state MUST flow through Supabase
  Auth; every table MUST have Row Level Security (RLS) enabled and explicit
  policies — client-side filtering is NOT a security boundary.
- **Transport**: All network traffic MUST use TLS 1.2+. App Transport Security
  exceptions MUST be justified in PR description and time-bounded.
- **Storage**: Tokens, refresh tokens, and PII MUST be stored in the iOS
  Keychain with `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly` or stricter.
  `UserDefaults` is forbidden for sensitive data.
- **Input handling**: All user input MUST be validated at the Domain layer
  (length, character class, semantic range). Supabase queries MUST use the
  SDK's parameterized APIs — no raw SQL string concatenation.
- **Logging**: Logs MUST NOT contain tokens, PII, or full request bodies in
  production builds. Use `OSLog` with the `.private` qualifier for sensitive
  interpolations.
- **Dependencies**: Third-party SPM packages MUST be pinned to an exact version
  and reviewed for CVEs before adoption.

**Rationale**: Mobile apps are shipped artefacts — a security defect once
released is permanently in users' hands. Preventive controls are the only
reliable line of defence.

## Technology & Platform Constraints

- **Language**: Swift 5.9+ with Swift Concurrency **allowed only at the
  boundary** (e.g. bridging Apple APIs); cross-layer async flows use RxSwift
  per Principle III.
- **UI framework**: SwiftUI (primary); UIKit interop only when justified.
- **Reactive framework**: RxSwift 6.x (`RxSwift`, `RxCocoa`, `RxRelay`).
  RxTest/RxBlocking for tests.
- **Backend**: Supabase (`supabase-swift` official SDK) providing Auth,
  Postgres, Storage, and Realtime. Direct database connections from the app
  are forbidden — traffic MUST go through Supabase's REST/Realtime APIs.
- **Minimum iOS version**: TODO(iOS_DEPLOYMENT_TARGET) — assume iOS 17+ until
  confirmed.
- **Dependency management**: Swift Package Manager only. CocoaPods and
  Carthage are disallowed. New dependencies require tech-lead approval
  documented in the PR.
- **Project structure**: One Xcode target for the app, one for unit tests,
  one for UI tests. Modularisation into SwiftPM local packages (per Clean
  Architecture layer) is RECOMMENDED once the app exceeds ~50 source files.
- **Linting & formatting**: SwiftLint MUST run as a build phase and in CI;
  warnings that violate style rules MUST fail CI. SwiftFormat MAY be adopted
  for auto-formatting.
- **Build**: Xcode 15+ on Apple Silicon. Reproducible builds via
  `Package.resolved` committed to the repository.

## Development Workflow & Quality Gates

- **Branching**: Trunk-based on `main`. Feature branches named
  `feat/<scope>-<short-desc>`; fix branches `fix/<scope>-<short-desc>`.
- **Commits**: Conventional Commits (`feat:`, `fix:`, `docs:`, `test:`,
  `refactor:`, `chore:`). Each commit MUST build and pass tests.
- **Pull requests**: Every change goes through a PR. PRs MUST:
  1. Link the related `.momorph/specs/` feature spec or an issue.
  2. Declare the affected Clean Architecture layers.
  3. Demonstrate that new Domain/ViewModel code is covered by unit tests
     written test-first (show the commit order or explain).
  4. Include a "Security review" checkbox when touching auth, storage,
     networking, or RLS.
  5. Be reviewed and approved by at least one engineer other than the author.
- **CI gates** (all MUST pass before merge):
  - `xcodebuild` clean build for Debug and Release.
  - Unit tests (XCTest + RxTest).
  - UI tests for touched user stories.
  - SwiftLint with zero violations.
  - Dependency vulnerability scan (e.g. GitHub Dependabot alerts reviewed).
- **In-phase validation cadence** (added 2026-04-27 after the M2 PR-M2.2
  iteration where per-task `xcodebuild test` runs caused 30–60 s
  simulator-launch tax × N tasks and frequently stalled the loop;
  amended same day to defer full-test runs to end-of-screen):
  - During implementation of a phase, run **`xcodebuild build-for-testing`**
    (compile-only, ~15 s) after each task or related-task batch — this
    catches ~90 % of failures (compile errors, type mismatches, missing
    imports) cheaply.
  - At a phase boundary inside a screen, the implementer **MAY** run a
    targeted subset (`-only-testing:<NewSuites>`) on the suites the
    phase added/changed — typically <30 s on a pre-booted sim. This is
    optional, not required.
  - The full **`xcodebuild test`** is run at one of:
    1. **End of a screen**: when every Phase under a single
       `.momorph/specs/<screen>/tasks.md` is `[x]`.
    2. **End of a screen-cluster**: when several related screens land
       together (e.g. M2 `Home` + sibling `Notifications`).
    3. **On explicit user request** ("hãy chạy full test", "run the
       full suite", etc.).
  - Per-phase full-suite runs are NOT required and SHOULD be skipped
    by default. The `build-for-testing` + targeted-subset pattern is
    sufficient to catch ~95 % of regressions inside a phase; the
    remaining 5 % surface at the screen-end full run before the
    cluster ships.
  - This is a developer-loop optimisation; CI gates are unchanged and
    still require the full test suite to pass before merge.
  - Pattern: write task → `build-for-testing` → write next task →
    `build-for-testing` → … → (phase end: optional targeted subset) →
    … → (screen end: full `xcodebuild test`).
  - **Test-run shortcuts** (verified 2026-04-27 during M2 PR-M2.2 —
    cut full-suite time from ~5 min to ~1.5 min):
    1. **Pre-boot the simulator once per session**:
       `xcrun simctl boot "iPhone 17"` — subsequent `xcodebuild test`
       reuses the booted sim instead of cold-booting (saves ~25 s/run).
    2. **Disable code coverage on the dev loop**:
       `xcodebuild test ... -enableCodeCoverage NO` (saves ~5–10 s/run).
       CI gates re-enable it.
    3. **Disable concurrent destination testing**:
       `xcodebuild test ... -disable-concurrent-destination-testing`
       avoids the per-suite simulator-clone tax.
    4. **Subset for inner loop**: `-only-testing:AIDD-SAA-2025Tests/<Suite>`
       runs just the suite touched (~10–20 s vs 1.5 min full).
  - **Driver vs TestScheduler trap** (lessons from M2 PR-M2.2):
    `Driver`'s `ConcurrentMainScheduler` async-hops events emitted
    from non-main schedulers; tests using `Observable<Int>.interval(scheduler: TestScheduler)`
    + `vm.driver.drive(testObserver)` HANG because the events never
    reach the observer under `scheduler.start()`. Fix: inject the
    tick / clock as an `Observable<Void>` parameter — production
    passes the real `interval`, tests pass a `PublishRelay<Void>`
    and emit synchronously. M1 `collect(driver.asObservable())`
    pattern then works without expectation/wait gymnastics.
- **Definition of Done**:
  - Acceptance scenarios from the feature spec demonstrated on simulator or
    device.
  - Accessibility pass (VoiceOver + Dynamic Type largest size) verified.
  - No new SwiftLint warnings, no `TODO` without an issue reference.
  - RLS policies updated and reviewed if Supabase schema changed.

## Governance

This constitution supersedes all prior informal conventions for the
AIDD-SAA-2025 project.

- **Amendment procedure**: Any engineer may propose an amendment via a PR that
  edits `.momorph/constitution.md`, updates the Sync Impact Report comment at
  the top of the file, bumps the version, and notifies the tech lead. The PR
  MUST be approved by the designated constitution owner
  (TODO(OWNER)) before merge.
- **Versioning policy**: Semantic versioning applies to the constitution
  itself:
  - **MAJOR**: a principle is removed or its meaning changes in a backward-
    incompatible way, or a governance rule is removed.
  - **MINOR**: a new principle or mandatory section is added, or an existing
    principle is materially expanded.
  - **PATCH**: wording clarifications, typo fixes, rationale edits that do
    not alter obligations.
- **Compliance review**: Every PR description MUST include a "Constitution
  check" line confirming the change is compliant, or listing justified
  exceptions. Quarterly, the tech lead reviews merged PRs for drift and opens
  remediation issues.
- **Complexity justification**: Any deviation (e.g. skipping tests, adopting
  a non-approved dependency, bypassing RxSwift for a specific flow) MUST be
  recorded inline in the code with a `// Constitution exemption: <reason>`
  comment and mirrored in the PR description.
- **Runtime guidance**: Day-to-day coding guidance lives in
  `.momorph/guidelines/frontend.md` and `.momorph/guidelines/backend.md`; when
  those documents conflict with this constitution, the constitution wins and
  the guidelines MUST be updated.

**Version**: 1.0.1 | **Ratified**: 2026-04-24 | **Last Amended**: 2026-04-24
