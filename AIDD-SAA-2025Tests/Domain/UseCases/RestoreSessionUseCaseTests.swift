import RxBlocking
import RxSwift
import XCTest
@testable import AIDD_SAA_2025

final class RestoreSessionUseCaseTests: XCTestCase {

    private var repository: MockAuthRepository!
    private var sut: RestoreSessionUseCase!

    override func setUp() {
        super.setUp()
        repository = MockAuthRepository()
        sut = RestoreSessionUseCase(repository: repository)
    }

    override func tearDown() {
        sut = nil
        repository = nil
        super.tearDown()
    }

    func test_execute_validCachedSession_returnsSignedIn() throws {
        let session = AuthSessionFixture.make()
        repository.restoreResult = .just(.signedIn(session))

        let state = try sut.execute().toBlocking().single()

        XCTAssertEqual(state, .signedIn(session))
        XCTAssertEqual(repository.restoreCalls, 1)
    }

    func test_execute_expiredSession_returnsSignedOut() throws {
        repository.restoreResult = .just(.signedOut)

        let state = try sut.execute().toBlocking().single()

        XCTAssertEqual(state, .signedOut)
    }

    func test_execute_preFirstUnlock_returnsSignedOutWithoutThrowing() throws {
        // Spec: pre-first-unlock keychain access must NOT throw — repository
        // swallows the read failure and surfaces `.signedOut` instead.
        repository.restoreResult = .just(.signedOut)

        let state = try sut.execute().toBlocking().single()

        XCTAssertEqual(state, .signedOut)
    }

    // MARK: - US4 forwarding (rich logic in AuthRepositoryImplTests)

    /// US4 AS1: foreground-return < access-token TTL → repo answers
    /// with `.signedIn` (cached); use case forwards verbatim.
    func test_execute_freshCachedSession_forwardsSignedIn() throws {
        let session = AuthSessionFixture.make()
        repository.restoreResult = .just(.signedIn(session))

        let state = try sut.execute().toBlocking().single()

        XCTAssertEqual(state, .signedIn(session))
    }

    /// US4 AS2: silent refresh succeeded inside the repo → use case
    /// forwards the rotated `.signedIn`.
    func test_execute_silentRefreshRotatedSession_forwardsSignedIn() throws {
        let rotated = AuthSessionFixture.make(accessToken: "new")
        repository.restoreResult = .just(.signedIn(rotated))

        let state = try sut.execute().toBlocking().single()

        XCTAssertEqual(state, .signedIn(rotated))
    }

    /// US4 AS3: both tokens expired → repo answers `.signedOut`.
    func test_execute_bothTokensExpired_forwardsSignedOut() throws {
        repository.restoreResult = .just(.signedOut)

        let state = try sut.execute().toBlocking().single()

        XCTAssertEqual(state, .signedOut)
    }
}
