# Tasks: [FEATURE_NAME]

**Frame**: `[FRAME_ID]-[FRAME_NAME]`
**Prerequisites**: plan.md (required), spec.md (required), research.md (recommended)

---

## Task Format

```
- [ ] T### [P?] [Story?] Description | file/path.swift
```

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this belongs to (US1, US2, US3)
- **|**: File path affected by this task
- **Test-first (constitution IV)**: Within a story, write Domain + ViewModel tests BEFORE their implementation tasks. Mark test tasks with `(TDD)`.

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and basic structure

- [ ] T001 Create / verify Clean-Architecture folder structure (`Presentation/`, `Domain/`, `Data/`, `Core/`) per plan.md
- [ ] T002 Add any missing SPM dependencies (RxSwift, RxCocoa, RxRelay, supabase-swift); pin exact versions
- [ ] T003 [P] Confirm SwiftLint build phase passes on new files; add rule overrides if required (justify in PR)
- [ ] T004 Load Figma-exported assets into `Assets.xcassets` per plan.md (colors as Color Sets with Light+Dark; images at 1x/2x/3x)
- [ ] T005 [P] Add new localization keys to `Resources/Localizable.xcstrings`

---

## Phase 2: Foundation (Blocking Prerequisites)

**Purpose**: Cross-feature infrastructure required by ALL user stories

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [ ] T006 Write Supabase migration(s) enabling RLS + policies for every new table | `supabase/migrations/*.sql`
- [ ] T007 [P] Add RLS policy integration tests (authorized / unauthorized / anonymous) | `AIDD-SAA-2025Tests/Data/*PolicyTests.swift`
- [ ] T008 [P] Register new use cases / repositories in DI composition root | `App/` + `Core/DI/`
- [ ] T009 [P] Extend shared `AppRoute` enum with new navigation values | `Presentation/Shared/Navigation/AppRoute.swift`
- [ ] T010 Configure any new environment values via `.xcconfig` (no secrets in git) | `Config/*.xcconfig`

**Checkpoint**: Foundation ready — user story implementation can now begin in parallel

---

## Phase 3: User Story 1 — [Title] (Priority: P1) 🎯 MVP

**Goal**: [Brief description of what this story delivers]

**Independent Test**: [XCUITest scenario name that verifies this story end-to-end]

### Domain (US1) — write tests first (Principle IV)

- [ ] T011 (TDD) [P] [US1] Write failing unit tests for `[DoSomething]UseCase` | `AIDD-SAA-2025Tests/Domain/UseCases/[DoSomething]UseCaseTests.swift`
- [ ] T012 [P] [US1] Define Domain entity | `Domain/Entities/[Entity].swift`
- [ ] T013 [P] [US1] Define repository protocol | `Domain/Repositories/[Feature]Repository.swift`
- [ ] T014 [US1] Implement `[DoSomething]UseCase` to pass T011 | `Domain/UseCases/[DoSomething]UseCase.swift`

### Data (US1)

- [ ] T015 [P] [US1] Define DTO + mapper | `Data/Remote/[Feature]/[Feature]DTO.swift`
- [ ] T016 (TDD) [US1] Write integration test for repository against staging Supabase | `AIDD-SAA-2025Tests/Data/[Feature]RepositoryIntegrationTests.swift`
- [ ] T017 [US1] Implement repository using Supabase SDK, wrapping async calls as `Single`/`Completable` | `Data/Repositories/[Feature]RepositoryImpl.swift`

### Presentation (US1) — Principle II + III

- [ ] T018 (TDD) [US1] Write ViewModel tests using `RxTest.TestScheduler` | `AIDD-SAA-2025Tests/Presentation/[Feature]/[Feature]ViewModelTests.swift`
- [ ] T019 [US1] Implement ViewModel (PublishRelay inputs, Driver/Signal outputs, DisposeBag) | `Presentation/[Feature]/ViewModels/[Feature]ViewModel.swift`
- [ ] T020 [US1] Implement Rx→SwiftUI state adapter | `Presentation/[Feature]/ViewModels/[Feature]StateAdapter.swift`
- [ ] T021 [US1] Build SwiftUI View — Dynamic Type, semantic colors, accessibility labels, 44pt targets | `Presentation/[Feature]/Views/[Feature]View.swift`
- [ ] T022 [P] [US1] Add any feature-local subviews | `Presentation/[Feature]/Components/`

### UI Tests (US1)

- [ ] T023 [US1] XCUITest covering the P1 acceptance scenario (using accessibility identifiers) | `AIDD-SAA-2025UITests/[Feature]/[Feature]UITests.swift`
- [ ] T024 [P] [US1] VoiceOver + AX5 Dynamic Type manual verification checklist entry in PR

**Checkpoint**: User Story 1 complete and independently testable

---

## Phase 4: User Story 2 — [Title] (Priority: P2)

**Goal**: [Brief description of what this story delivers]
**Independent Test**: [XCUITest scenario name]

### Domain (US2)

- [ ] T025 (TDD) [P] [US2] UseCase tests | `AIDD-SAA-2025Tests/Domain/UseCases/`
- [ ] T026 [US2] UseCase implementation | `Domain/UseCases/`

### Data (US2)

- [ ] T027 [P] [US2] DTO + mapper | `Data/Remote/[Feature]/`
- [ ] T028 [US2] Repository extension + integration test | `Data/Repositories/` + `AIDD-SAA-2025Tests/Data/`

### Presentation (US2)

- [ ] T029 (TDD) [US2] ViewModel tests | `AIDD-SAA-2025Tests/Presentation/[Feature]/`
- [ ] T030 [US2] ViewModel + View | `Presentation/[Feature]/`

### UI Tests (US2)

- [ ] T031 [US2] XCUITest for P2 scenario | `AIDD-SAA-2025UITests/[Feature]/`

**Checkpoint**: User Stories 1 & 2 complete

---

## Phase 5: User Story 3 — [Title] (Priority: P3)

**Goal**: [Brief description of what this story delivers]
**Independent Test**: [XCUITest scenario name]

### Domain (US3)

- [ ] T032 (TDD) [P] [US3] UseCase tests | `AIDD-SAA-2025Tests/Domain/UseCases/`
- [ ] T033 [US3] UseCase implementation | `Domain/UseCases/`

### Data (US3)

- [ ] T034 [P] [US3] DTO + repository changes | `Data/`
- [ ] T035 [US3] Integration test against staging Supabase | `AIDD-SAA-2025Tests/Data/`

### Presentation (US3)

- [ ] T036 (TDD) [US3] ViewModel tests | `AIDD-SAA-2025Tests/Presentation/[Feature]/`
- [ ] T037 [US3] ViewModel + View | `Presentation/[Feature]/`

### UI Tests (US3)

- [ ] T038 [P] [US3] XCUITest for P3 scenario | `AIDD-SAA-2025UITests/[Feature]/`

**Checkpoint**: All user stories complete

---

## Phase N: Polish & Cross-Cutting Concerns

**Purpose**: Refinements affecting multiple stories

- [ ] TXXX [P] Loading / empty / error states consistent across Views (Principle II)
- [ ] TXXX [P] Accessibility sweep — VoiceOver walkthrough + Dynamic Type AX5 on every P1/P2 screen (Principle II)
- [ ] TXXX [P] Localization audit — no hard-coded user-facing strings remain (Principle II)
- [ ] TXXX Performance: Instruments trace on cold launch + primary user flow
- [ ] TXXX Security review (Principle V): confirm no new secrets committed; Keychain usage audited; RLS policies reviewed; logs scrubbed of PII
- [ ] TXXX Code cleanup: remove dead code, unused imports, stale TODOs
- [ ] TXXX Constitution-check line added to PR description citing Principles I–V

---

## Security Review Gate (Principle V — REQUIRED before merge)

- [ ] No secret / key committed (grep `SUPABASE_SERVICE_ROLE`, `SECRET`, `.env`)
- [ ] Every new/altered Supabase table has RLS enabled + policies + policy tests
- [ ] Tokens / PII stored only in Keychain with `AfterFirstUnlockThisDeviceOnly` (or stricter)
- [ ] All new network traffic is TLS; no ATS exceptions added (or one is justified in PR)
- [ ] Input validation exists at Domain boundary for every external input
- [ ] Logs reviewed: no tokens / full request bodies / PII in release-level logs
- [ ] Any new SPM dependency reviewed for CVEs and pinned to an exact version

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phase 3+)**: All depend on Foundational phase completion
  - User stories can then proceed in parallel (if staffed)
  - Or sequentially in priority order (P1 → P2 → P3)
- **Polish (Final Phase)**: Depends on all desired user stories being complete


### Within Each User Story

- Tests (if included) MUST be written and FAIL before implementation
- Models before services
- Services before endpoints
- Core implementation before integration
- Story complete before moving to next priority

### Parallel Opportunities

- All Setup tasks marked [P] can run in parallel
- All Foundational tasks marked [P] can run in parallel (within Phase 2)
- Once Foundational phase completes, all user stories can start in parallel (if team capacity allows)
- All tests for a user story marked [P] can run in parallel
- Models within a story marked [P] can run in parallel
- Different user stories can be worked on in parallel by different team members

---

## Implementation Strategy

### MVP First (Recommended)

1. Complete Phase 1 + 2
2. Complete Phase 3 (User Story 1 only)
3. **STOP and VALIDATE**: Test independently
4. Deploy if ready

### Incremental Delivery

1. Setup + Foundation
2. Add User Story 1 → Test → Deploy
3. Add User Story 2 → Test → Deploy
4. Add User Story 3 → Test → Deploy

---

## Notes

- Commit after each task or logical group
- Run tests before moving to next phase
- Update spec.md if requirements change during implementation
- Mark tasks complete as you go: `[x]`
