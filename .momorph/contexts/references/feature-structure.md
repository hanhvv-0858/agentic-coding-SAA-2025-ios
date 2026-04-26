# Feature Structure

Use this layout for each SwiftUI feature under `Presentation/Screens/`:

```text
Presentation/
  Screens/
    <Feature>/
      <Feature>Model.swift            # Recommended, not required for tiny static screens
      <Feature>View.swift
      <Feature>Service.swift          # Optional, when feature owns local service contract
      <Feature>PreviewData.swift      # Optional, recommended for preview-heavy UIs
      <Feature>ModelTests.swift       # Optional in folder; can live in Tests/PresentationTests
```

## Naming Rules

- Name views as `<Feature>View`.
- Name state owner as `<Feature>Model` when the screen needs state/side effects.
- Name service protocol as `<Feature>Service`.
- Name domain item as `<Feature>Item` unless domain language suggests a better term.

## Responsibility Split

- `<Feature>View`: compose layout, bind state, forward user intents.
- `<Feature>Model`: hold mutable state, orchestrate async work, map errors to user-facing state.
- `<Feature>Service`: define `Sendable` feature-facing data contract when needed.
- `<Feature>PreviewData`: provide static fake data for previews.
- `<Feature>ModelTests`: verify state transitions and error handling.

For tiny static screens, omit `<Feature>Model` and keep logic inside `View` strictly presentation-only.

## Swift 6 Guardrails

- Mark `<Feature>Model` with `@MainActor`.
- Keep async boundary types (`<Feature>Item`, service outputs, errors) `Sendable` where possible.
- Prefer deterministic stubs in `<Feature>ModelTests` over network-backed fakes.
