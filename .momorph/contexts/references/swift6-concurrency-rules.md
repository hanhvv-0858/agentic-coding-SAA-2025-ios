# Swift 6 Concurrency Rules

Apply these rules by default when generating or reviewing code.

## Isolation

- Isolate feature models with `@MainActor`.
- Keep UI state mutation on the main actor only.
- Avoid mixing actor-isolated state changes with background mutation.

## Sendable Boundaries

- Make service protocols `Sendable`.
- Make async payload types (`Item`, DTO, domain values) `Sendable`.
- Avoid storing non-`Sendable` closures in service types unless isolation makes it safe.

## Cancellation

- Treat cancellation as a control flow outcome, not an error UX state.
- Catch `CancellationError` separately.
- Avoid setting user-facing error state when work was only cancelled.

## Task Discipline

- Avoid `Task.detached` for feature screen logic.
- Start async work from explicit intents (`onAppear`, `didTapRetry`).
- Guard duplicate loads when `isLoading` is already true.

## Error Mapping

- Map unknown errors to stable user-facing messages.
- Keep raw technical errors out of default UI text.
