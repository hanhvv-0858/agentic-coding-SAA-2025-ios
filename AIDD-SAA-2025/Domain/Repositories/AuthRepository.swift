import Foundation
import RxSwift

protocol AuthRepository: AnyObject {
    func observe() -> Observable<AuthState>

    /// Returns the OAuth session WITHOUT persisting or emitting `.signedIn`.
    /// Caller is responsible for calling `acceptSession(_:)` once domain
    /// validation passes (US2 — disallowed-domain flow MUST sign out
    /// before the AuthStore ever flips to `.signedIn`).
    func signInWithGoogle() -> Single<AuthSession>

    /// Same contract as `signInWithGoogle` for the deep-link callback path.
    func exchangeCallback(_ url: URL) -> Single<AuthSession>

    /// Persist the session to Keychain and flip `AuthStore` to `.signedIn`.
    /// MUST only be called after the domain check passes.
    func acceptSession(_ session: AuthSession) -> Completable

    /// Signs out via SDK + clears local Keychain + flips `AuthStore` to
    /// `.signedOut`. The Keychain delete MUST happen BEFORE the
    /// Completable returns, even if the SDK call fails (SEC_02).
    func signOut() -> Completable

    func restoreSession() -> Single<AuthState>
}
