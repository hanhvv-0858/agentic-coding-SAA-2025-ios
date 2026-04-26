import Security
import XCTest
@testable import AIDD_SAA_2025

final class KeychainPurgerTests: XCTestCase {

    /// End-to-end: write a session via `KeychainSessionStorage`, then
    /// run the purger against the same service. The session must be
    /// gone after.
    func test_purgeAll_clearsKeychainSessionStorage_entry() throws {
        let service = "test.purger.\(UUID().uuidString)"
        let storage = KeychainSessionStorage(service: service, account: "sb.session")
        let session = AuthSession(
            accessToken: "a",
            refreshToken: "r",
            expiresAt: Date().addingTimeInterval(3600).rounded(),
            user: AuthUser(id: UUID(), email: "alice@sun-asterisk.com")
        )
        try storage.write(session)
        XCTAssertNotNil(try storage.read())

        KeychainPurger(services: [service]).purgeAll()

        XCTAssertNil(try storage.read())
    }

    /// Multiple services purged in one pass; one is empty (nothing to
    /// delete) — the purger must not fail on `errSecItemNotFound`.
    func test_purgeAll_multipleServices_handlesMissingItemsGracefully() throws {
        let service1 = "test.purger.\(UUID().uuidString)"
        let service2 = "test.purger.\(UUID().uuidString)" // never written

        let storage = KeychainSessionStorage(service: service1, account: "sb.session")
        try storage.write(AuthSession(
            accessToken: "a",
            refreshToken: "r",
            expiresAt: Date().addingTimeInterval(3600).rounded(),
            user: AuthUser(id: UUID(), email: "alice@sun-asterisk.com")
        ))

        KeychainPurger(services: [service1, service2]).purgeAll()

        XCTAssertNil(try storage.read())
    }

    /// Services we don't list must NOT be touched.
    func test_purgeAll_doesNotTouchUnlistedServices() throws {
        let kept = "test.purger.kept.\(UUID().uuidString)"
        let purged = "test.purger.purged.\(UUID().uuidString)"

        let keptStorage = KeychainSessionStorage(service: kept, account: "sb.session")
        let purgedStorage = KeychainSessionStorage(service: purged, account: "sb.session")
        defer { try? keptStorage.delete() } // cleanup

        let session = AuthSession(
            accessToken: "a",
            refreshToken: "r",
            expiresAt: Date().addingTimeInterval(3600).rounded(),
            user: AuthUser(id: UUID(), email: "alice@sun-asterisk.com")
        )
        try keptStorage.write(session)
        try purgedStorage.write(session)

        KeychainPurger(services: [purged]).purgeAll()

        XCTAssertNotNil(try keptStorage.read(), "Unlisted service must be untouched")
        XCTAssertNil(try purgedStorage.read())
    }
}

private extension Date {
    /// JSON encoding via `secondsSince1970` is lossy at sub-second
    /// precision, which would break Equatable on round-trip.
    func rounded() -> Date {
        Date(timeIntervalSince1970: floor(timeIntervalSince1970))
    }
}
