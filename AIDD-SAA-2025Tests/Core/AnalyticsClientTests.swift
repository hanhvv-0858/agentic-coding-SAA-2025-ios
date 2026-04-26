import XCTest
@testable import AIDD_SAA_2025

final class AnalyticsClientTests: XCTestCase {

    func test_event_loginDenied_carriesEmailDomainOnly_neverFullEmail() {
        let event = AnalyticsEvent.loginDenied(emailDomain: "gmail.com")

        XCTAssertEqual(event.name, "login.denied")
        XCTAssertEqual(event.properties, ["email_domain": "gmail.com"])
        // Spec: never log full email. The associated value is a domain
        // (no `@`), so the event payload cannot contain a full address.
        XCTAssertFalse(event.properties.values.contains(where: { $0.contains("@") }))
    }

    func test_event_loginError_carriesCodeOnly() {
        let event = AnalyticsEvent.loginError(code: "network")

        XCTAssertEqual(event.name, "login.error")
        XCTAssertEqual(event.properties, ["code": "network"])
    }

    func test_event_loginSuccess_carriesNoProperties() {
        XCTAssertTrue(AnalyticsEvent.loginSuccess.properties.isEmpty)
    }

    func test_event_loginViewed_carriesNoProperties() {
        XCTAssertTrue(AnalyticsEvent.loginViewed.properties.isEmpty)
    }
}

final class MockAnalyticsClient: AnalyticsClient, @unchecked Sendable {
    private let lock = NSLock()
    private var _tracked: [AnalyticsEvent] = []

    var tracked: [AnalyticsEvent] {
        lock.lock(); defer { lock.unlock() }
        return _tracked
    }

    func track(_ event: AnalyticsEvent) {
        lock.lock(); defer { lock.unlock() }
        _tracked.append(event)
    }
}

/// Equatable conformance scoped to the test bundle so we can assert on
/// emitted events without polluting the production type.
extension AnalyticsEvent: @retroactive Equatable {
    public static func == (lhs: AnalyticsEvent, rhs: AnalyticsEvent) -> Bool {
        switch (lhs, rhs) {
        case (.loginViewed, .loginViewed),
             (.loginGoogleTapped, .loginGoogleTapped),
             (.loginSuccess, .loginSuccess):
            return true
        case (.loginDenied(let l), .loginDenied(let r)):
            return l == r
        case (.loginError(let l), .loginError(let r)):
            return l == r
        default:
            return false
        }
    }
}
