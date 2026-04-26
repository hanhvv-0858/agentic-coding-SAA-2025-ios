import XCTest
@testable import AIDD_SAA_2025

final class KeychainSessionStorageTests: XCTestCase {

    private var storage: KeychainSessionStorage!
    private let service = "test.aidd.saa.keychain"
    private let account = "test.session"

    override func setUp() {
        super.setUp()
        storage = KeychainSessionStorage(service: service, account: account)
        try? storage.delete()
    }

    override func tearDown() {
        try? storage.delete()
        storage = nil
        super.tearDown()
    }

    private func makeSession(email: String = "alice@sun-asterisk.com") -> AuthSession {
        // Round to whole seconds — JSON encoding via `.secondsSince1970`
        // is lossy at sub-second precision and would break Equatable.
        let expiresAt = Date(timeIntervalSince1970: floor(Date().addingTimeInterval(3600).timeIntervalSince1970))
        return AuthSession(
            accessToken: "access-\(UUID().uuidString)",
            refreshToken: "refresh-\(UUID().uuidString)",
            expiresAt: expiresAt,
            user: AuthUser(id: UUID(), email: email)
        )
    }

    func test_read_whenEmpty_returnsNil() throws {
        XCTAssertNil(try storage.read())
    }

    func test_writeThenRead_roundTripsSession() throws {
        let session = makeSession()
        try storage.write(session)

        let restored = try XCTUnwrap(try storage.read())
        XCTAssertEqual(restored, session)
    }

    func test_write_overwritesExistingSession() throws {
        try storage.write(makeSession(email: "first@sun-asterisk.com"))
        let second = makeSession(email: "second@sun-asterisk.com")
        try storage.write(second)

        XCTAssertEqual(try storage.read(), second)
    }

    func test_delete_removesSession() throws {
        try storage.write(makeSession())
        try storage.delete()
        XCTAssertNil(try storage.read())
    }

    func test_delete_whenEmpty_doesNotThrow() {
        XCTAssertNoThrow(try storage.delete())
    }

    func test_storedItem_usesAfterFirstUnlockThisDeviceOnly() throws {
        try storage.write(makeSession())

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnAttributes as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        XCTAssertEqual(status, errSecSuccess)

        let attributes = try XCTUnwrap(result as? [String: Any])
        let accessibility = attributes[kSecAttrAccessible as String] as? String
        XCTAssertEqual(accessibility, kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly as String)
    }
}
