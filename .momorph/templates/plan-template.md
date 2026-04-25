# Implementation Plan: [FEATURE_NAME]

**Frame**: `[FRAME_ID]-[FRAME_NAME]`
**Date**: [DATE]
**Spec**: `specs/[FRAME_ID]-[FRAME_NAME]/spec.md`

---

## Summary

[Extract from feature spec: primary requirement + technical approach from research]

---

## Technical Context

**Language/Framework**: Swift 5.9+ / SwiftUI (iOS 17+)
**Primary Dependencies**: RxSwift 6.x (RxCocoa, RxRelay), supabase-swift SDK
**Backend**: Supabase (Postgres + Auth + Storage + Realtime + Edge Functions)
**Testing**: XCTest + RxTest/RxBlocking for unit, XCUITest for UI
**Architecture**: Clean Architecture (Presentation / Domain / Data / Core)
**Reactive model**: RxSwift across layer boundaries; Swift Concurrency only at SDK boundaries
**Feature-specific deviations**: [List any — must be justified in Violations table]

---

## Constitution Compliance Check

*GATE: Must pass before implementation can begin. Cite each principle by name.*

- [ ] **I. Clean Architecture**: Presentation/Domain/Data layering preserved; dependencies point inward; Domain imports no frameworks.
- [ ] **II. SwiftUI-First & HIG**: New screens built in SwiftUI; Dynamic Type + VoiceOver + 44×44pt touch targets verified; semantic colors / Light+Dark handled; no hard-coded user-facing strings.
- [ ] **III. Reactive Data Flow with RxSwift**: Cross-layer async modelled as `Observable`/`Single`/`Completable`; ViewModels expose Rx I/O; no Rx imports inside SwiftUI Views; `DisposeBag` ownership + explicit schedulers.
- [ ] **IV. Test-First**: Unit tests written before implementation for new Domain + ViewModel code; RxTest `TestScheduler` used; no coverage regression in Domain layer.
- [ ] **V. Secure-by-Default**: No secrets in repo; service-role key absent from app bundle; RLS policies added/updated for every new table; Keychain (not UserDefaults) for tokens/PII; TLS-only; input validated at Domain boundary; logs scrubbed of PII.

**Violations (if any)**:

| Violation | Principle | Justification | Alternative Rejected | Exemption location |
|-----------|-----------|---------------|---------------------|--------------------|
| [e.g., Combine used instead of Rx for X] | III | [Why needed] | [Why Rx won't work] | [file:line with `// Constitution exemption:` comment] |

---

## Architecture Decisions

### Presentation Layer (SwiftUI + RxSwift)

- **Screen inventory**: [List new SwiftUI screens + existing screens modified]
- **ViewModel contracts**: [Inputs (PublishRelay) / Outputs (Driver/Signal) per screen]
- **State adapter**: [How Rx outputs bridge to `@Published` in Views]
- **Navigation**: [New `AppRoute` cases; NavigationStack vs sheet/full-screen]
- **HIG compliance**: [Dynamic Type, semantic colors, VoiceOver labels, localization keys]

### Domain Layer

- **Use cases**: [List new use cases: `SignInUseCase`, `FetchProfileUseCase`, …]
- **Entities**: [New/modified Domain entities]
- **Repository protocols**: [New/extended protocols]
- **Validation**: [Input validation rules enforced at the Domain boundary]

### Data Layer (Supabase)

- **Tables touched**: [List — mark NEW vs MODIFIED]
- **RLS policies**: [New/updated policies; unauthorized-access test cases]
- **DTOs & mappers**: [`ProfileDTO` → `Profile` entity]
- **Storage buckets**: [If any, with access policies]
- **Edge Functions**: [If service-role work is required, list functions]

### Integration Points

- **Supabase services used**: [Auth / Postgres / Storage / Realtime / Edge Functions]
- **Shared components**: [Reusable SwiftUI components / Rx operators / Domain use cases]
- **Secrets touched**: [Any `.xcconfig` or Supabase secret additions]

---

## Project Structure

### Documentation (this feature)

```text
.momorph/specs/[FRAME_ID]-[FRAME_NAME]/
├── spec.md              # Feature specification
├── plan.md              # This file
├── research.md          # Codebase research findings
├── tasks.md             # Task breakdown (next step)
├── testcase.md          # (optional) Test cases
└── contract.md          # (optional) API contracts
```

### Source Code (affected areas)

```text
# App target — AIDD-SAA-2025/
Presentation/[Feature]/
├── Views/[Feature]View.swift
├── ViewModels/[Feature]ViewModel.swift
├── ViewModels/[Feature]StateAdapter.swift
└── Components/                 # Feature-local reusable subviews

Domain/
├── Entities/[Entity].swift
├── UseCases/[DoSomething]UseCase.swift
└── Repositories/[Feature]Repository.swift   # protocol only

Data/
├── Repositories/[Feature]RepositoryImpl.swift
├── Remote/[Feature]/[Feature]RemoteDataSource.swift
├── Remote/[Feature]/[Feature]DTO.swift
└── Local/[Feature]/[Feature]LocalDataSource.swift   # if caching

Core/
├── DI/                         # wire new use cases + repos
└── Extensions/                 # only if reused across features

Resources/
└── Localizable.xcstrings       # new keys added here

# Supabase (if schema changes)
supabase/
├── migrations/YYYYMMDDHHMMSS_[feature].sql
└── functions/[function-name]/index.ts        # if Edge Function required

# Tests
AIDD-SAA-2025Tests/
├── Domain/UseCases/[UseCase]Tests.swift
├── Presentation/[Feature]/[ViewModel]Tests.swift
└── Data/[Feature]/[Repository]IntegrationTests.swift

AIDD-SAA-2025UITests/
└── [Feature]/[Feature]UITests.swift
```

---

## Implementation Strategy

### Phase Breakdown

1. **Setup**: Project scaffolding, dependencies
2. **Foundation**: Shared infrastructure, base components
3. **User Story 1 (P1)**: Core MVP functionality
4. **User Story 2 (P2)**: Enhanced features
5. **User Story 3 (P3)**: Additional features
6. **Polish**: Refinements, optimizations

### Risk Assessment

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| [Risk 1] | [Low/Med/High] | [Low/Med/High] | [Strategy] |
| [Risk 2] | [Low/Med/High] | [Low/Med/High] | [Strategy] |

### Estimated Complexity

- **Frontend**: [Low/Medium/High]
- **Backend**: [Low/Medium/High]
- **Testing**: [Low/Medium/High]

---

## Integration Testing Strategy

### Test Scope

*Define what needs integration testing for this feature:*

- [ ] **Component/Module interactions**: [List internal components that need integration verification]
- [ ] **External dependencies**: [List external services, APIs, or systems to test against]
- [ ] **Data layer**: [Database, storage, cache - if applicable]
- [ ] **User workflows**: [End-to-end flows spanning multiple components]

### Test Categories

*Select applicable categories and define specific test scenarios:*

| Category | Applicable? | Key Scenarios |
|----------|-------------|---------------|
| View ↔ ViewModel (Rx → SwiftUI state) | [Yes/No] | [e.g., Loading/error/success binding] |
| UseCase ↔ Repository | [Yes/No] | [e.g., Fetch + cache + error translation] |
| Repository ↔ Supabase | [Yes/No] | [e.g., CRUD with RLS authorized & denied cases] |
| Auth flow (Supabase Auth ↔ Keychain) | [Yes/No] | [e.g., Sign-in, refresh, sign-out clears Keychain] |
| RLS policy enforcement | [Yes/No] | [e.g., Owner-only read, anonymous denied] |
| Accessibility (VoiceOver + Dynamic Type) | [Yes/No] | [e.g., All P1 screens announce correctly at AX5] |

### Test Environment

- **Environment type**: [e.g., Local, Staging, Emulator/Simulator, Test containers]
- **Test data strategy**: [e.g., Fixtures, Factories, Seeded database, Mock server]
- **Isolation approach**: [e.g., Fresh state per test, Transaction rollback, Sandboxed environment]

### Mocking Strategy

| Dependency Type | Strategy | Rationale |
|-----------------|----------|-----------|
| [e.g., Core services] | [Real/Mock/Stub] | [Why this choice] |
| [e.g., External APIs] | [Real/Mock/Stub] | [Why this choice] |
| [e.g., Platform features] | [Real/Mock/Stub] | [Why this choice] |

### Test Scenarios Outline

*List key integration test scenarios for this feature:*

1. **Happy Path**
   - [ ] [Scenario description]
   - [ ] [Scenario description]

2. **Error Handling**
   - [ ] [Scenario description]
   - [ ] [Scenario description]

3. **Edge Cases**
   - [ ] [Scenario description]
   - [ ] [Scenario description]

### Tooling & Framework

- **Test framework**: XCTest (unit), RxTest/RxBlocking (Rx), XCUITest (UI)
- **Supporting tools**: Supabase staging project (seeded per-run), `deno test` for Edge Functions
- **CI integration**: `xcodebuild test` for iOS; RLS policy tests run against staging project on merge to `main`

### Coverage Goals

| Area | Target | Priority |
|------|--------|----------|
| [e.g., Core user flows] | [e.g., 90%+] | [High/Medium/Low] |
| [e.g., Integration points] | [e.g., 85%+] | [High/Medium/Low] |
| [e.g., Error scenarios] | [e.g., 75%+] | [High/Medium/Low] |

---

## Dependencies & Prerequisites

### Required Before Start

- [ ] `constitution.md` reviewed and understood
- [ ] `spec.md` approved by stakeholders
- [ ] `research.md` completed
- [ ] API contracts defined (if applicable)
- [ ] Database migrations planned (if applicable)

### External Dependencies

- [List any external APIs, services, or resources needed]

---

## Next Steps

After plan approval:

1. **Run** `/momorph.tasks` to generate task breakdown
2. **Review** tasks.md for parallelization opportunities
3. **Begin** implementation following task order

---

## Notes

[Any additional context, assumptions, or design decisions]
