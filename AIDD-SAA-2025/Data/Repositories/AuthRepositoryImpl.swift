import Foundation
import RxRelay
import RxSwift
import os

/// Composes the Supabase data source, the Keychain session storage, and
/// the in-memory `AuthStore`. Single source of truth for the
/// `AuthState` stream the rest of the app subscribes to.
nonisolated final class AuthRepositoryImpl: AuthRepository {

    private let dataSource: SupabaseAuthDataSource
    private let sessionStorage: SessionStoring
    private let authStore: AuthStoring

    init(
        dataSource: SupabaseAuthDataSource,
        sessionStorage: SessionStoring,
        authStore: AuthStoring
    ) {
        self.dataSource = dataSource
        self.sessionStorage = sessionStorage
        self.authStore = authStore
    }

    func observe() -> Observable<AuthState> {
        authStore.stateObservable
    }

    func signInWithGoogle() -> Single<AuthSession> {
        // Returns the session as-is; persistence is deferred to
        // `acceptSession(_:)` so the caller can validate the email
        // domain BEFORE we flip `AuthStore` or write the Keychain.
        dataSource.signInWithGoogle()
    }

    func exchangeCallback(_ url: URL) -> Single<AuthSession> {
        dataSource.exchangeCallback(url)
    }

    func acceptSession(_ session: AuthSession) -> Completable {
        Completable.create { [weak self] observer in
            guard let self else {
                observer(.completed)
                return Disposables.create()
            }
            self.persist(session)
            observer(.completed)
            return Disposables.create()
        }
    }

    func signOut() -> Completable {
        // Spec SEC_02: Keychain MUST be cleared synchronously and the
        // store MUST emit `.signedOut` BEFORE the Completable returns —
        // even if the SDK signOut fails — so no caller can act on a
        // half-cleared session.
        Completable.create { [weak self] observer in
            guard let self else {
                observer(.completed)
                return Disposables.create()
            }

            let sdk = self.dataSource.signOut()
                .do(onError: { error in
                    Log.auth.warning("SDK signOut failed: \(String(describing: error), privacy: .public)")
                })
                .catch { _ in .empty() }

            return sdk.subscribe(onCompleted: {
                self.clearLocalSession()
                observer(.completed)
            })
        }
    }

    /// Restore policy (US1 + US4):
    /// - No cached session → `.signedOut`.
    /// - Cached & still within access-token TTL → `.signedIn` (no SDK call).
    /// - Cached but access expired → silent refresh via SDK; on success
    ///   persist the rotated session and emit `.signedIn`; on failure
    ///   (refresh expired / network issue / invalid_grant) clear the
    ///   Keychain and emit `.signedOut`.
    /// - Keychain unreadable (pre-first-unlock) → `.signedOut` without
    ///   surfacing the error.
    func restoreSession() -> Single<AuthState> {
        let stored: AuthSession?
        do {
            stored = try sessionStorage.read()
        } catch {
            Log.auth.info("Keychain unreadable on restore — treating as signedOut")
            authStore.state.accept(.signedOut)
            return .just(.signedOut)
        }

        guard let session = stored else {
            authStore.state.accept(.signedOut)
            return .just(.signedOut)
        }

        if !session.isExpired {
            // Push the Keychain-restored session into the SDK BEFORE
            // emitting signedIn. Without this, PostgREST/Realtime calls
            // go out with the anon key and RLS-protected reads return
            // empty (silently). `refreshSession()` already sets the SDK
            // session as a side effect, so we only need this branch.
            return dataSource.setSDKSession(
                accessToken: session.accessToken,
                refreshToken: session.refreshToken
            )
            .andThen(Single.deferred { [weak self] in
                self?.authStore.state.accept(.signedIn(session))
                return .just(.signedIn(session))
            })
            .catch { [weak self] _ -> Single<AuthState> in
                // SDK rejected the restored tokens — treat as signed-out.
                guard let self else { return .just(.signedOut) }
                Log.auth.info("SDK rejected restored session — clearing cache")
                try? self.sessionStorage.delete()
                self.authStore.state.accept(.signedOut)
                return .just(.signedOut)
            }
        }

        // US4 silent refresh: access expired, but refresh token may
        // still be valid. Try once; if the SDK rejects, treat as
        // fully signed-out and purge the Keychain.
        return dataSource.refreshSession(refreshToken: session.refreshToken)
            .flatMap { [weak self] refreshed -> Single<AuthState> in
                guard let self else { return .just(.signedOut) }
                self.persist(refreshed)
                return .just(.signedIn(refreshed))
            }
            .catch { [weak self] _ -> Single<AuthState> in
                guard let self else { return .just(.signedOut) }
                Log.auth.info("Silent refresh failed — clearing cached session")
                try? self.sessionStorage.delete()
                self.authStore.state.accept(.signedOut)
                return .just(.signedOut)
            }
    }

    private func persist(_ session: AuthSession) {
        do {
            try sessionStorage.write(session)
        } catch {
            Log.auth.error("Failed to persist session to Keychain: \(String(describing: error), privacy: .public)")
        }
        authStore.state.accept(.signedIn(session))
    }

    private func clearLocalSession() {
        do {
            try sessionStorage.delete()
        } catch {
            Log.auth.error("Failed to clear Keychain on signOut: \(String(describing: error), privacy: .public)")
        }
        authStore.state.accept(.signedOut)
    }
}
