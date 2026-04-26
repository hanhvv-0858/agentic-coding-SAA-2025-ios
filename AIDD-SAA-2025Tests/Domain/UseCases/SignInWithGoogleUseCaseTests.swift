import RxBlocking
import RxSwift
import XCTest
@testable import AIDD_SAA_2025

final class SignInWithGoogleUseCaseTests: XCTestCase {

    private var repository: MockAuthRepository!
    private var sut: SignInWithGoogleUseCase!

    private let allowlist = AllowedEmailDomains(domains: ["sun-asterisk.com"])

    override func setUp() {
        super.setUp()
        repository = MockAuthRepository()
        sut = SignInWithGoogleUseCase(
            repository: repository,
            checkEmailDomain: CheckEmailDomainUseCase(allowlist: allowlist)
        )
    }

    override func tearDown() {
        sut = nil
        repository = nil
        super.tearDown()
    }

    // MARK: - Allowed domain

    func test_execute_allowedDomain_acceptsSessionAndEmitsIt() throws {
        let session = AuthSessionFixture.make(email: "alice@sun-asterisk.com")
        repository.signInResult = .just(session)

        let result = try sut.execute().toBlocking().single()

        XCTAssertEqual(result, session)
        XCTAssertEqual(repository.acceptedSessions, [session])
        XCTAssertEqual(repository.signOutCalls, 0)
    }

    // MARK: - Disallowed domain (US2 core security ordering)

    func test_execute_disallowedDomain_signsOutBeforeFailing() throws {
        let session = AuthSessionFixture.make(email: "bob@gmail.com")
        repository.signInResult = .just(session)

        XCTAssertThrowsError(try sut.execute().toBlocking().single()) { error in
            XCTAssertEqual(error as? AuthError, .disallowedDomain)
        }

        // Spec: signOut() MUST be called BEFORE navigating, and the
        // session MUST never reach `acceptSession` (otherwise AuthStore
        // would briefly flip to .signedIn).
        XCTAssertEqual(repository.signOutCalls, 1)
        XCTAssertTrue(repository.acceptedSessions.isEmpty)
    }

    func test_execute_emptyEmail_treatedAsDisallowed() {
        let session = AuthSessionFixture.make(email: "")
        repository.signInResult = .just(session)

        XCTAssertThrowsError(try sut.execute().toBlocking().single()) { error in
            XCTAssertEqual(error as? AuthError, .disallowedDomain)
        }
        XCTAssertEqual(repository.signOutCalls, 1)
    }

    // MARK: - SDK error propagation

    func test_execute_networkError_propagates_withoutSignOut() {
        repository.signInResult = .error(AuthError.network)

        XCTAssertThrowsError(try sut.execute().toBlocking().single()) { error in
            XCTAssertEqual(error as? AuthError, .network)
        }
        XCTAssertEqual(repository.signOutCalls, 0)
        XCTAssertTrue(repository.acceptedSessions.isEmpty)
    }

    func test_execute_serviceUnavailable_propagates() {
        repository.signInResult = .error(AuthError.serviceUnavailable)

        XCTAssertThrowsError(try sut.execute().toBlocking().single()) { error in
            XCTAssertEqual(error as? AuthError, .serviceUnavailable)
        }
    }

    func test_execute_cancelled_propagates() {
        repository.signInResult = .error(AuthError.cancelled)

        XCTAssertThrowsError(try sut.execute().toBlocking().single()) { error in
            XCTAssertEqual(error as? AuthError, .cancelled)
        }
        XCTAssertEqual(repository.signOutCalls, 0)
    }

    func test_execute_unknown_propagates() {
        repository.signInResult = .error(AuthError.unknown("boom"))

        XCTAssertThrowsError(try sut.execute().toBlocking().single()) { error in
            XCTAssertEqual(error as? AuthError, .unknown("boom"))
        }
    }
}
