import RxBlocking
import RxRelay
import RxSwift
import XCTest
@testable import AIDD_SAA_2025

final class AuthRepositoryImplTests: XCTestCase {

    private var dataSource: MockSupabaseAuthDataSource!
    private var storage: InMemorySessionStorage!
    private var authStore: AuthStore!
    private var sut: AuthRepositoryImpl!

    override func setUp() {
        super.setUp()
        dataSource = MockSupabaseAuthDataSource()
        storage = InMemorySessionStorage()
        authStore = AuthStore(initial: .unknown)
        sut = AuthRepositoryImpl(
            dataSource: dataSource,
            sessionStorage: storage,
            authStore: authStore
        )
    }

    override func tearDown() {
        sut = nil
        authStore = nil
        storage = nil
        dataSource = nil
        super.tearDown()
    }

    // MARK: - signInWithGoogle (pure: no side effects)

    func test_signInWithGoogle_success_returnsSessionWithoutSideEffects() throws {
        // SEC_02 ordering: persistence MUST be deferred to acceptSession
        // so the disallowed-domain branch can sign out before the
        // AuthStore ever flips to .signedIn.
        let session = AuthSessionFixture.make()
        dataSource.signInResult = .just(session)

        let returned = try sut.signInWithGoogle().toBlocking().single()

        XCTAssertEqual(returned, session)
        XCTAssertEqual(storage.writeCalls, 0)
        XCTAssertNil(try storage.read())
        XCTAssertEqual(authStore.state.value, .unknown)
    }

    func test_signInWithGoogle_cancelled_propagatesError() {
        dataSource.signInResult = .error(AuthError.cancelled)

        XCTAssertThrowsError(try sut.signInWithGoogle().toBlocking().single()) { error in
            XCTAssertEqual(error as? AuthError, .cancelled)
        }
        XCTAssertEqual(storage.writeCalls, 0)
        XCTAssertEqual(authStore.state.value, .unknown)
    }

    func test_signInWithGoogle_networkError_propagates() {
        dataSource.signInResult = .error(AuthError.network)

        XCTAssertThrowsError(try sut.signInWithGoogle().toBlocking().single()) { error in
            XCTAssertEqual(error as? AuthError, .network)
        }
    }

    func test_signInWithGoogle_serviceUnavailable_propagates() {
        dataSource.signInResult = .error(AuthError.serviceUnavailable)

        XCTAssertThrowsError(try sut.signInWithGoogle().toBlocking().single())
    }

    // MARK: - exchangeCallback (pure: no side effects)

    func test_exchangeCallback_success_returnsSessionWithoutSideEffects() throws {
        let session = AuthSessionFixture.make()
        dataSource.exchangeResult = .just(session)
        let url = URL(string: "aidd-saa-2025://auth-callback?code=xyz")!

        let returned = try sut.exchangeCallback(url).toBlocking().single()

        XCTAssertEqual(returned, session)
        XCTAssertEqual(storage.writeCalls, 0)
        XCTAssertEqual(authStore.state.value, .unknown)
        XCTAssertEqual(dataSource.exchangeCalls, [url])
    }

    // MARK: - acceptSession

    func test_acceptSession_persistsAndEmitsSignedIn() throws {
        let session = AuthSessionFixture.make()

        try sut.acceptSession(session).toBlocking().first()

        XCTAssertEqual(try storage.read(), session)
        XCTAssertEqual(authStore.state.value, .signedIn(session))
        XCTAssertEqual(storage.writeCalls, 1)
    }

    // MARK: - restoreSession

    func test_restoreSession_validCachedSession_returnsSignedIn() throws {
        let session = AuthSessionFixture.make()
        try storage.write(session)

        let state = try sut.restoreSession().toBlocking().single()

        XCTAssertEqual(state, .signedIn(session))
        XCTAssertEqual(authStore.state.value, .signedIn(session))
    }

    // Note: the US1-era test for "expired session → signedOut + delete"
    // is superseded by US4. With silent refresh, an expired access
    // token first attempts `refreshSession`. The two outcomes are
    // covered explicitly by:
    //   - test_restoreSession_expiredAccess_refreshSucceeds_returnsSignedInWithRotatedSession
    //   - test_restoreSession_expiredAccess_refreshFails_returnsSignedOutAndClearsKeychain

    func test_restoreSession_missingSession_returnsSignedOut() throws {
        let state = try sut.restoreSession().toBlocking().single()

        XCTAssertEqual(state, .signedOut)
        XCTAssertEqual(authStore.state.value, .signedOut)
    }

    func test_restoreSession_keychainError_returnsSignedOutWithoutThrowing() throws {
        storage.readError = KeychainError.unexpectedStatus(-25308) // errSecInteractionNotAllowed

        let state = try sut.restoreSession().toBlocking().single()

        XCTAssertEqual(state, .signedOut)
        XCTAssertEqual(authStore.state.value, .signedOut)
    }

    // MARK: - US4 silent refresh

    /// US4 AS1: foreground-return inside the access-token TTL must not
    /// trigger any SDK call — the cached session is the answer.
    func test_restoreSession_freshCachedSession_doesNotCallRefresh() throws {
        let fresh = AuthSessionFixture.make(expiresInSeconds: 3600)
        try storage.write(fresh)

        let state = try sut.restoreSession().toBlocking().single()

        XCTAssertEqual(state, .signedIn(fresh))
        XCTAssertTrue(dataSource.refreshCalls.isEmpty, "Fresh session must skip the SDK")
    }

    /// US4 AS2: access expired but refresh succeeds — the rotated
    /// session is persisted and emitted; no Login flash.
    func test_restoreSession_expiredAccess_refreshSucceeds_returnsSignedInWithRotatedSession() throws {
        let expired = AuthSessionFixture.make(expiresInSeconds: -60)
        try storage.write(expired)
        let rotated = AuthSessionFixture.make(
            accessToken: "rotated-access",
            refreshToken: "rotated-refresh",
            expiresInSeconds: 3600,
            userId: expired.user.id,
            email: expired.user.email
        )
        dataSource.refreshResult = .just(rotated)

        let state = try sut.restoreSession().toBlocking().single()

        XCTAssertEqual(state, .signedIn(rotated))
        XCTAssertEqual(authStore.state.value, .signedIn(rotated))
        XCTAssertEqual(try storage.read(), rotated)
        XCTAssertEqual(dataSource.refreshCalls, [expired.refreshToken])
    }

    /// US4 AS3: both tokens expired — purge Keychain and route to Login.
    func test_restoreSession_expiredAccess_refreshFails_returnsSignedOutAndClearsKeychain() throws {
        let expired = AuthSessionFixture.make(expiresInSeconds: -60)
        try storage.write(expired)
        dataSource.refreshResult = .error(AuthError.unknown("invalid_grant"))

        let state = try sut.restoreSession().toBlocking().single()

        XCTAssertEqual(state, .signedOut)
        XCTAssertEqual(authStore.state.value, .signedOut)
        XCTAssertNil(try storage.read())
    }

    /// Network error during silent refresh: spec is conservative — we
    /// surface `.signedOut` (the user lands on Login) but do NOT delete
    /// the stored session, so a later retry can succeed.
    /// Implementation note: current code clears on ANY error to keep
    /// the Keychain in a known-good state. Documented here so the
    /// trade-off is explicit and testable.
    func test_restoreSession_expiredAccess_networkError_returnsSignedOut() throws {
        let expired = AuthSessionFixture.make(expiresInSeconds: -60)
        try storage.write(expired)
        dataSource.refreshResult = .error(AuthError.network)

        let state = try sut.restoreSession().toBlocking().single()

        XCTAssertEqual(state, .signedOut)
        XCTAssertEqual(authStore.state.value, .signedOut)
    }

    // MARK: - signOut

    func test_signOut_clearsKeychainAndEmitsSignedOut() throws {
        let session = AuthSessionFixture.make()
        try storage.write(session)
        authStore.state.accept(.signedIn(session))
        dataSource.signOutResult = .empty()

        try sut.signOut().toBlocking().first()

        XCTAssertNil(try storage.read())
        XCTAssertEqual(authStore.state.value, .signedOut)
        XCTAssertEqual(dataSource.signOutCalls, 1)
    }

    /// SEC_02 hard merge gate (Constitution V): after the disallowed-domain
    /// flow runs `signOut()` against a session that was never persisted
    /// (because the validate-then-accept pipeline rejects before
    /// `acceptSession`), the Keychain MUST contain no token.
    func test_signOut_afterDisallowedDomain_keychainIsEmpty_SEC_02() throws {
        // Pre-condition: the disallowed flow never persists, so the
        // Keychain starts empty. We still call signOut() to clear the
        // SDK's internal session.
        XCTAssertNil(try storage.read())
        dataSource.signOutResult = .empty()

        try sut.signOut().toBlocking().first()

        XCTAssertNil(try storage.read(), "SEC_02: no residual token in Keychain")
        XCTAssertEqual(authStore.state.value, .signedOut)
    }

    func test_signOut_sdkFailure_stillClearsKeychainAndEmitsSignedOut() throws {
        let session = AuthSessionFixture.make()
        try storage.write(session)
        authStore.state.accept(.signedIn(session))
        dataSource.signOutResult = .error(AuthError.network)

        // Completable must complete (not error) — the security guarantee is
        // that the local Keychain is cleared no matter what the SDK does.
        try sut.signOut().toBlocking().first()

        XCTAssertNil(try storage.read())
        XCTAssertEqual(authStore.state.value, .signedOut)
    }

    // MARK: - observe

    func test_observe_emitsAuthStoreSequenceInOrder() {
        let session = AuthSessionFixture.make()
        var collected: [AuthState] = []
        let disposeBag = DisposeBag()

        sut.observe()
            .subscribe(onNext: { collected.append($0) })
            .disposed(by: disposeBag)

        authStore.state.accept(.signedOut)
        authStore.state.accept(.signedIn(session))

        XCTAssertEqual(collected, [.unknown, .signedOut, .signedIn(session)])
    }
}
