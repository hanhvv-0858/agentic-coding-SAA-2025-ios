# Project Review Checklist

Use this checklist for app-wide architecture review.

## Structure

- Verify project has clear `App`, `Domain`, `Application`, `Data`, `Presentation`, and `Infrastructure` boundaries.
- Verify screen features are grouped under `Presentation/Screens/<Feature>`.
- Verify design system assets are grouped under `Presentation/DesignSystem`.

## Dependency Graph

- Verify dependency direction is `Presentation -> Application -> Domain`.
- Verify `Data` depends on `Domain` contracts and does not leak into `Presentation`.
- Verify `Domain` does not import upper layers.

## Composition and DI

- Verify one composition root (`AppContainer`) creates concrete implementations.
- Verify `Presentation` models receive dependencies through initializers.
- Verify no hidden global singleton usage for use case or data dependencies.

## Navigation

- Verify app-level routes are defined centrally.
- Verify `RootView` owns `NavigationStack` and route transitions.
- Verify feature models expose intents, not app route coupling.
- Verify native SwiftUI navigation APIs are default unless complexity requires a dedicated navigator.

## Concurrency and Tests

- Verify app-shared services are safe under Swift 6 concurrency checks.
- Verify feature async logic keeps success/failure/cancellation model tests.
- Verify tests exist at least for `DomainTests`, `ApplicationTests`, `DataTests`, and `PresentationTests`.
