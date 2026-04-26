# Testing Playbook

Use this playbook when generating tests for SwiftUI MV features.

## Required Test Set

- One success test: verify data is populated and error is nil.
- One failure test: verify data is cleared and error is set.
- One cancellation test: verify no false error UI is shown for cancellation.

## Test Design Rules

- Use async/await tests instead of callback expectations when possible.
- Test model behavior through public intent methods (`onAppear`, `didTapRetry`).
- Use deterministic service stubs with explicit response modes.
- Avoid real network, disk, and clock dependencies in unit tests.

## State Assertions

- Assert `isLoading` is false at the end of each flow.
- Assert `items` transitions are intentional for each branch.
- Assert `errorMessage` transitions are intentional for each branch.

## Stub Pattern

Use one stub with a typed response enum:

```swift
private struct FeatureServiceStub: FeatureService {
    enum Response: Sendable { case success([FeatureItem]), failure, cancelled }
    let response: Response

    func fetchItems() async throws -> [FeatureItem] {
        switch response {
        case let .success(items): return items
        case .failure: throw StubError.failed
        case .cancelled: throw CancellationError()
        }
    }
}
```
