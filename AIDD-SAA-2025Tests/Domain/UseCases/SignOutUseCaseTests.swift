import RxBlocking
import RxRelay
import RxSwift
import XCTest
@testable import AIDD_SAA_2025

final class SignOutUseCaseTests: XCTestCase {

    func test_execute_completes() throws {
        let repo = MockAuthRepository()
        repo.signOutResult = .empty()
        let sut = SignOutUseCase(repository: repo)

        try sut.execute().toBlocking().first()

        XCTAssertEqual(repo.signOutCalls, 1)
    }

    func test_execute_clearsKeychainAndEmitsSignedOut_throughRepository() throws {
        // The use case is a thin wrapper — the actual Keychain delete
        // and AuthStore emission are exercised by AuthRepositoryImplTests.
        // This test verifies the use case forwards the same Completable.
        let dataSource = MockSupabaseAuthDataSource()
        dataSource.signOutResult = .empty()
        let storage = InMemorySessionStorage(initial: AuthSessionFixture.make())
        let authStore = AuthStore(initial: .signedIn(AuthSessionFixture.make()))
        let repo = AuthRepositoryImpl(
            dataSource: dataSource,
            sessionStorage: storage,
            authStore: authStore
        )
        let sut = SignOutUseCase(repository: repo)

        try sut.execute().toBlocking().first()

        XCTAssertNil(try storage.read())
        XCTAssertEqual(authStore.state.value, .signedOut)
    }
}
