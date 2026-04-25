# Feature Specification: [FEATURE_NAME]

**Frame ID**: `[FRAME_ID]`
**Frame Name**: `[FRAME_NAME]`
**File Key**: `[FILE_KEY]`
**Created**: [DATE]
**Status**: Draft

---

## Overview

[Brief description of the feature based on Figma design analysis]

---

## User Scenarios & Testing *(mandatory)*

<!--
  IMPORTANT: User stories should be PRIORITIZED as user journeys ordered by importance.
  Each user story/journey must be INDEPENDENTLY TESTABLE - meaning if you implement just ONE of them,
  you should still have a viable MVP (Minimum Viable Product) that delivers value.

  Assign priorities (P1, P2, P3, etc.) to each story, where P1 is the most critical.
-->

### User Story 1 - [Brief Title] (Priority: P1)

[Describe this user journey in plain language]

**Why this priority**: [Explain the value and why it has this priority level]

**Independent Test**: [Describe how this can be tested independently]

**Acceptance Scenarios**:

1. **Given** [initial state], **When** [action], **Then** [expected outcome]
2. **Given** [initial state], **When** [action], **Then** [expected outcome]

---

### User Story 2 - [Brief Title] (Priority: P2)

[Describe this user journey in plain language]

**Why this priority**: [Explain the value and why it has this priority level]

**Independent Test**: [Describe how this can be tested independently]

**Acceptance Scenarios**:

1. **Given** [initial state], **When** [action], **Then** [expected outcome]

---

### User Story 3 - [Brief Title] (Priority: P3)

[Describe this user journey in plain language]

**Why this priority**: [Explain the value and why it has this priority level]

**Independent Test**: [Describe how this can be tested independently]

**Acceptance Scenarios**:

1. **Given** [initial state], **When** [action], **Then** [expected outcome]

---

[Add more user stories as needed, each with an assigned priority]

### Edge Cases

- What happens when [boundary condition]?
- How does system handle [error scenario]?

---

## UI/UX Requirements *(from Figma)*

### Screen Components

| Component | Description | Interactions |
|-----------|-------------|--------------|
| [Component 1] | [Description] | [Click, hover, etc.] |
| [Component 2] | [Description] | [Click, hover, etc.] |

### Navigation Flow

- From: [Previous screen/state]
- To: [Next screen/state]
- Triggers: [User actions that cause navigation]

### Visual Requirements (iOS / HIG — Principle II)

- **Device support**: iPhone (portrait primary); iPad behaviour if applicable.
- **Appearance**: Light + Dark mode both supported with semantic colors.
- **Dynamic Type**: MUST render correctly from `.xSmall` through `.accessibility5`.
- **Animations/Transitions**: [List — keep ≤ 350 ms unless justified]
- **Accessibility (MANDATORY)**:
  - Every interactive element has `accessibilityLabel` and, where useful, `accessibilityHint`.
  - Touch targets ≥ 44×44 pt.
  - VoiceOver walk-through verified for the P1 user story.
  - Color contrast ≥ 4.5:1 for text.
- **Localization**: All user-facing strings are keys in `Localizable.xcstrings` — list new keys here.

---

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST [specific capability]
- **FR-002**: System MUST [specific capability]
- **FR-003**: Users MUST be able to [key interaction]
- **FR-004**: System MUST [data requirement]
- **FR-005**: System MUST [behavior]

### Technical Requirements

- **TR-001 (Performance)**: [e.g., Cold-launch screen renders first content in <2s on iPhone 12]
- **TR-002 (Security — Principle V)**: [e.g., Auth tokens stored in Keychain with `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`; no secrets in logs]
- **TR-003 (Supabase RLS — Principle V)**: [List each touched table + the policy rule: who can SELECT / INSERT / UPDATE / DELETE]
- **TR-004 (Reactive boundaries — Principle III)**: [ViewModel inputs/outputs listed; DisposeBag ownership identified]
- **TR-005 (Offline / error)**: [Behaviour on network loss; retry semantics]

### Key Entities *(if feature involves data)*

- **[Entity 1]**: [Domain entity attributes; which Supabase table it maps from]
- **[Entity 2]**: [Relationships; RLS ownership column]

---

## Supabase Dependencies

### Tables / Views

| Table | Access | RLS policy required | Status |
|-------|--------|---------------------|--------|
| [public.profiles] | [SELECT/INSERT/UPDATE] | [owner-only by `auth.uid() = user_id`] | [Exists/New] |

### Storage

| Bucket | Access pattern | Policy | Status |
|--------|----------------|--------|--------|
| [avatars] | [read public, write owner] | [owner = `auth.uid()`] | [Exists/New] |

### Edge Functions

| Function | Trigger | Why service-role needed | Status |
|----------|---------|-------------------------|--------|
| [send-invite] | [REST POST] | [sends email via third-party] | [Exists/New] |

---

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: [Measurable metric]
- **SC-002**: [User satisfaction metric]
- **SC-003**: [Business metric]

---

## Out of Scope

- [Feature/functionality explicitly NOT included]
- [Future enhancement to be addressed later]

---

## Dependencies

- [ ] Constitution document exists (`.momorph/constitution.md`)
- [ ] API specifications available (`.momorph/API.yml`)
- [ ] Database design completed (`.momorph/database.sql`)
- [ ] Screen flow documented (`.momorph/SCREENFLOW.md`)

---

## Notes

[Any additional context, assumptions, or clarifications]
