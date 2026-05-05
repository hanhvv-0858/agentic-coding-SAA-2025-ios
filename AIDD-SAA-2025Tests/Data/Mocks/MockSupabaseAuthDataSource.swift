import Foundation
import RxSwift
@testable import AIDD_SAA_2025

final class MockSupabaseAuthDataSource: SupabaseAuthDataSource {

    var signInResult: Single<AuthSession> = .never()
    var exchangeResult: Single<AuthSession> = .never()
    var refreshResult: Single<AuthSession> = .never()
    var signOutResult: Completable = .empty()
    var currentSessionResult: Single<AuthSession?> = .just(nil)
    var setSDKSessionResult: Completable = .empty()

    private(set) var signInCalls = 0
    private(set) var exchangeCalls: [URL] = []
    private(set) var refreshCalls: [String] = []
    private(set) var signOutCalls = 0
    private(set) var currentSessionCalls = 0
    private(set) var setSDKSessionCalls: [(accessToken: String, refreshToken: String)] = []

    func signInWithGoogle() -> Single<AuthSession> {
        signInCalls += 1
        return signInResult
    }

    func exchangeCallback(_ url: URL) -> Single<AuthSession> {
        exchangeCalls.append(url)
        return exchangeResult
    }

    func refreshSession(refreshToken: String) -> Single<AuthSession> {
        refreshCalls.append(refreshToken)
        return refreshResult
    }

    func signOut() -> Completable {
        signOutCalls += 1
        return signOutResult
    }

    func currentSession() -> Single<AuthSession?> {
        currentSessionCalls += 1
        return currentSessionResult
    }

    func setSDKSession(accessToken: String, refreshToken: String) -> Completable {
        setSDKSessionCalls.append((accessToken, refreshToken))
        return setSDKSessionResult
    }
}

final class InMemorySessionStorage: SessionStoring {

    private var stored: AuthSession?
    var readError: Error?
    var writeError: Error?
    var deleteError: Error?

    private(set) var readCalls = 0
    private(set) var writeCalls = 0
    private(set) var deleteCalls = 0

    init(initial: AuthSession? = nil) {
        self.stored = initial
    }

    func read() throws -> AuthSession? {
        readCalls += 1
        if let readError { throw readError }
        return stored
    }

    func write(_ session: AuthSession) throws {
        writeCalls += 1
        if let writeError { throw writeError }
        stored = session
    }

    func delete() throws {
        deleteCalls += 1
        if let deleteError { throw deleteError }
        stored = nil
    }
}
