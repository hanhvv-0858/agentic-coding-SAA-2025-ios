import Foundation
import RxSwift
@testable import AIDD_SAA_2025

final class MockAuthRepository: AuthRepository {

    var observeStream: Observable<AuthState> = .empty()
    var signInResult: Single<AuthSession> = .never()
    var exchangeResult: Single<AuthSession> = .never()
    var acceptSessionResult: Completable = .empty()
    var signOutResult: Completable = .empty()
    var restoreResult: Single<AuthState> = .just(.signedOut)

    private(set) var observeCalls = 0
    private(set) var signInCalls = 0
    private(set) var exchangeCalls: [URL] = []
    private(set) var acceptedSessions: [AuthSession] = []
    private(set) var signOutCalls = 0
    private(set) var restoreCalls = 0

    func observe() -> Observable<AuthState> {
        observeCalls += 1
        return observeStream
    }

    func signInWithGoogle() -> Single<AuthSession> {
        signInCalls += 1
        return signInResult
    }

    func exchangeCallback(_ url: URL) -> Single<AuthSession> {
        exchangeCalls.append(url)
        return exchangeResult
    }

    func acceptSession(_ session: AuthSession) -> Completable {
        acceptedSessions.append(session)
        return acceptSessionResult
    }

    func signOut() -> Completable {
        signOutCalls += 1
        return signOutResult
    }

    func restoreSession() -> Single<AuthState> {
        restoreCalls += 1
        return restoreResult
    }
}

enum AuthSessionFixture {
    static func make(
        accessToken: String = "access-token",
        refreshToken: String = "refresh-token",
        expiresInSeconds: TimeInterval = 3600,
        userId: UUID = UUID(),
        email: String = "alice@sun-asterisk.com"
    ) -> AuthSession {
        AuthSession(
            accessToken: accessToken,
            refreshToken: refreshToken,
            expiresAt: Date().addingTimeInterval(expiresInSeconds),
            user: AuthUser(id: userId, email: email)
        )
    }
}
