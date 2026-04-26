# Review Checklist

Use this checklist when reviewing SwiftUI MV code:

- Verify the view does not call networking or persistence APIs directly.
- Verify model omission is limited to tiny static screens with no side effects and no business logic.
- Verify the model owns all mutable screen state when a model is present.
- Verify the model is `@MainActor`, `@Observable`, and `final` when a model is present.
- Verify async flows update `isLoading`, success data, and errors consistently.
- Verify `CancellationError` is handled separately from true failure.
- Verify service contracts are protocol-based, `Sendable`, and mockable.
- Verify data crossing async boundaries is `Sendable`.
- Verify previews exercise at least loading, success, and error states.
- Verify model tests cover success, failure, and cancellation transitions.
- Verify no `Task.detached` is used for feature screen logic.
- Verify naming follows `<Feature>Model` and `<Feature>View` conventions.

When scope is app-wide architecture, also run `references/project-review-checklist.md`.
