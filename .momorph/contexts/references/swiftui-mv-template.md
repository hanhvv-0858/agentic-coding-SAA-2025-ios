# SwiftUI MV Template

## Model Template

```swift
import Foundation
import Observation

@MainActor
@Observable
final class <Feature>Model {
    private let service: any <Feature>Service

    var isLoading = false
    var items: [<Feature>Item] = []
    var errorMessage: String?

    init(service: any <Feature>Service) {
        self.service = service
    }

    func onAppear() async {
        guard items.isEmpty else { return }
        await load()
    }

    func didTapRetry() async {
        await load()
    }

    private func load() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            items = try await service.fetchItems()
        } catch is CancellationError {
            // Ignore cancellation so the UI does not show a false error state.
        } catch {
            items = []
            errorMessage = "Failed to load data."
        }
    }
}
```

## View Template

```swift
import SwiftUI

struct <Feature>View: View {
    @State private var model: <Feature>Model

    init(model: <Feature>Model) {
        _model = State(initialValue: model)
    }

    var body: some View {
        content
            .task {
                await model.onAppear()
            }
            .refreshable {
                await model.didTapRetry()
            }
    }

    @ViewBuilder
    private var content: some View {
        if model.isLoading {
            ProgressView()
        } else if let errorMessage = model.errorMessage {
            VStack(spacing: 12) {
                Text(errorMessage)
                Button("Retry") {
                    Task { await model.didTapRetry() }
                }
            }
        } else {
            List(model.items) { item in
                Text(item.title)
            }
        }
    }
}
```

## Service Template

```swift
import Foundation

protocol <Feature>Service: Sendable {
    func fetchItems() async throws -> [<Feature>Item]
}

struct <Feature>Item: Identifiable, Sendable, Equatable {
    let id: UUID
    let title: String
}
```

## Model Test Template

```swift
import XCTest
@testable import YourModuleName

@MainActor
final class <Feature>ModelTests: XCTestCase {
    func test_onAppear_loadsItemsOnSuccess() async {
        let expected: [<Feature>Item] = [.init(id: UUID(), title: "A")]
        let service = <Feature>ServiceStub(response: .success(expected))
        let model = <Feature>Model(service: service)

        await model.onAppear()

        XCTAssertEqual(model.items, expected)
        XCTAssertNil(model.errorMessage)
        XCTAssertFalse(model.isLoading)
    }

    func test_onAppear_setsErrorOnFailure() async {
        let service = <Feature>ServiceStub(response: .failure)
        let model = <Feature>Model(service: service)

        await model.onAppear()

        XCTAssertTrue(model.items.isEmpty)
        XCTAssertEqual(model.errorMessage, "Failed to load data.")
        XCTAssertFalse(model.isLoading)
    }

    func test_didTapRetry_ignoresCancellation() async {
        let initial: [<Feature>Item] = [.init(id: UUID(), title: "Keep")]
        let service = <Feature>ServiceStub(response: .cancelled)
        let model = <Feature>Model(service: service)
        model.items = initial

        await model.didTapRetry()

        XCTAssertEqual(model.items, initial)
        XCTAssertNil(model.errorMessage)
        XCTAssertFalse(model.isLoading)
    }
}

private struct <Feature>ServiceStub: <Feature>Service {
    enum Response: Sendable {
        case success([<Feature>Item])
        case failure
        case cancelled
    }

    let response: Response

    func fetchItems() async throws -> [<Feature>Item] {
        switch response {
        case let .success(items):
            return items
        case .failure:
            throw StubError.failed
        case .cancelled:
            throw CancellationError()
        }
    }

    private enum StubError: Error, Sendable {
        case failed
    }
}
```
