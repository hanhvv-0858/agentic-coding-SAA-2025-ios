import XCTest
@testable import AIDD_SAA_2025

final class AuthSessionTests: XCTestCase {

    private func makeUser(email: String) -> AuthUser {
        AuthUser(id: UUID(), email: email)
    }

    func test_emailDomain_isLowercased() {
        XCTAssertEqual(makeUser(email: "Alice@Sun-Asterisk.COM").emailDomain, "sun-asterisk.com")
    }

    func test_emailDomain_takesSubstringAfterLastAt() {
        XCTAssertEqual(makeUser(email: "weird@local@example.com").emailDomain, "example.com")
    }

    func test_emailDomain_trimsSurroundingWhitespace() {
        XCTAssertEqual(makeUser(email: "  alice@sun-asterisk.com  ").emailDomain, "sun-asterisk.com")
    }

    func test_emailDomain_isNFCNormalised() {
        let composed = "alice@bücker.de"
        let decomposed = "alice@bu\u{0308}cker.de"
        XCTAssertEqual(makeUser(email: composed).emailDomain, makeUser(email: decomposed).emailDomain)
        XCTAssertEqual(makeUser(email: decomposed).emailDomain, "bücker.de")
    }

    func test_emailDomain_emptyWhenNoAtSign() {
        XCTAssertEqual(makeUser(email: "noatsign").emailDomain, "")
    }

    func test_emailDomain_emptyWhenAtIsLastChar() {
        XCTAssertEqual(makeUser(email: "alice@").emailDomain, "")
    }
}
