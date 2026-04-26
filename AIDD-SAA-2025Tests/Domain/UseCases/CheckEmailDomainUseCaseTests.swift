import XCTest
@testable import AIDD_SAA_2025

final class CheckEmailDomainUseCaseTests: XCTestCase {

    private let allowlist = AllowedEmailDomains(domains: ["sun-asterisk.com"])

    private func makeSession(email: String) -> AuthSession {
        AuthSession(
            accessToken: "a",
            refreshToken: "r",
            expiresAt: Date().addingTimeInterval(3600),
            user: AuthUser(id: UUID(), email: email)
        )
    }

    func test_allowlistedDomain_returnsSuccess() {
        let sut = CheckEmailDomainUseCase(allowlist: allowlist)
        let session = makeSession(email: "alice@sun-asterisk.com")

        let result = sut.execute(session)

        XCTAssertEqual(try result.get(), session)
    }

    func test_disallowedDomain_returnsDisallowedFailure() {
        let sut = CheckEmailDomainUseCase(allowlist: allowlist)
        let session = makeSession(email: "bob@gmail.com")

        let result = sut.execute(session)

        XCTAssertThrowsError(try result.get()) { error in
            XCTAssertEqual(error as? AuthError, .disallowedDomain)
        }
    }

    func test_missingEmail_returnsDisallowedFailure() {
        let sut = CheckEmailDomainUseCase(allowlist: allowlist)
        let session = makeSession(email: "")

        let result = sut.execute(session)

        XCTAssertThrowsError(try result.get()) { error in
            XCTAssertEqual(error as? AuthError, .disallowedDomain)
        }
    }

    func test_emailWithoutAtSign_returnsDisallowedFailure() {
        let sut = CheckEmailDomainUseCase(allowlist: allowlist)
        let session = makeSession(email: "noatsign")

        let result = sut.execute(session)

        XCTAssertThrowsError(try result.get())
    }

    func test_unicodeDomain_isNFCNormalisedAndLowercasedBeforeCheck() {
        // The allowlist contains the NFC-composed `bücker.de`. The session
        // arrives with the NFD-decomposed form (`bu` + combining diaeresis).
        // After normalisation they must match.
        let unicodeAllowlist = AllowedEmailDomains(domains: ["bücker.de"])
        let sut = CheckEmailDomainUseCase(allowlist: unicodeAllowlist)
        let decomposed = "alice@bu\u{0308}cker.DE"
        let session = makeSession(email: decomposed)

        let result = sut.execute(session)

        XCTAssertEqual(try? result.get(), session)
    }
}
