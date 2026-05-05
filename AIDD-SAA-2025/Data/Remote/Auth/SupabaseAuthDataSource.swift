import Foundation
import RxSwift
import Supabase
import os

#if canImport(AuthenticationServices)
import AuthenticationServices
#endif

protocol SupabaseAuthDataSource: AnyObject {
    func signInWithGoogle() -> Single<AuthSession>
    func exchangeCallback(_ url: URL) -> Single<AuthSession>
    func refreshSession(refreshToken: String) -> Single<AuthSession>
    func signOut() -> Completable
    func currentSession() -> Single<AuthSession?>
    /// Pushes a session restored from our own Keychain back into the
    /// Supabase SDK so subsequent PostgREST/Realtime/Storage calls go
    /// out with `Authorization: Bearer <accessToken>` instead of the
    /// anon key. Without this step, RLS-protected reads return empty
    /// even though our `authStore` reports `.signedIn`.
    func setSDKSession(accessToken: String, refreshToken: String) -> Completable
}

/// Live data source backed by `supabase-swift` Auth. Bridges the SDK's
/// `async` API to RxSwift `Single`/`Completable` and translates SDK
/// errors into `AuthError` cases the Domain layer can reason about.
nonisolated final class SupabaseAuthDataSourceImpl: SupabaseAuthDataSource {

    private let client: SupabaseClient
    private let redirectURL: URL
    private let scheduler: ImmediateSchedulerType

    init(
        client: SupabaseClient,
        redirectURL: URL,
        scheduler: ImmediateSchedulerType = ConcurrentDispatchQueueScheduler(qos: .userInitiated)
    ) {
        self.client = client
        self.redirectURL = redirectURL
        self.scheduler = scheduler
    }

    func signInWithGoogle() -> Single<AuthSession> {
        Single<AuthSession>.create { [weak self] observer in
            guard let self else {
                observer(.failure(AuthError.unknown("data source deallocated")))
                return Disposables.create()
            }

            let task = Task { [weak self] in
                guard let self else { return }
                do {
                    let session = try await self.client.auth.signInWithOAuth(
                        provider: .google,
                        redirectTo: self.redirectURL
                    )
                    observer(.success(AuthDTO.toDomain(session)))
                } catch {
                    observer(.failure(Self.map(error)))
                }
            }

            return Disposables.create { task.cancel() }
        }
        .subscribe(on: scheduler)
    }

    func exchangeCallback(_ url: URL) -> Single<AuthSession> {
        Single<AuthSession>.create { [weak self] observer in
            guard let self else {
                observer(.failure(AuthError.unknown("data source deallocated")))
                return Disposables.create()
            }

            let task = Task { [weak self] in
                guard let self else { return }
                do {
                    let session = try await self.client.auth.session(from: url)
                    observer(.success(AuthDTO.toDomain(session)))
                } catch {
                    observer(.failure(Self.map(error)))
                }
            }

            return Disposables.create { task.cancel() }
        }
        .subscribe(on: scheduler)
    }

    func refreshSession(refreshToken: String) -> Single<AuthSession> {
        Single<AuthSession>.create { [weak self] observer in
            guard let self else {
                observer(.failure(AuthError.unknown("data source deallocated")))
                return Disposables.create()
            }

            let task = Task { [weak self] in
                guard let self else { return }
                do {
                    let session = try await self.client.auth.refreshSession(refreshToken: refreshToken)
                    observer(.success(AuthDTO.toDomain(session)))
                } catch {
                    observer(.failure(Self.map(error)))
                }
            }

            return Disposables.create { task.cancel() }
        }
        .subscribe(on: scheduler)
    }

    func signOut() -> Completable {
        Completable.create { [weak self] observer in
            guard let self else {
                observer(.completed)
                return Disposables.create()
            }

            let task = Task { [weak self] in
                guard let self else { return }
                do {
                    try await self.client.auth.signOut()
                    observer(.completed)
                } catch {
                    observer(.error(Self.map(error)))
                }
            }

            return Disposables.create { task.cancel() }
        }
        .subscribe(on: scheduler)
    }

    func setSDKSession(accessToken: String, refreshToken: String) -> Completable {
        Completable.create { [weak self] observer in
            guard let self else {
                observer(.completed)
                return Disposables.create()
            }

            let task = Task { [weak self] in
                guard let self else { return }
                do {
                    _ = try await self.client.auth.setSession(
                        accessToken: accessToken,
                        refreshToken: refreshToken
                    )
                    observer(.completed)
                } catch {
                    observer(.error(Self.map(error)))
                }
            }

            return Disposables.create { task.cancel() }
        }
        .subscribe(on: scheduler)
    }

    func currentSession() -> Single<AuthSession?> {
        Single<AuthSession?>.create { [weak self] observer in
            guard let self else {
                observer(.success(nil))
                return Disposables.create()
            }

            if let session = self.client.auth.currentSession {
                observer(.success(AuthDTO.toDomain(session)))
            } else {
                observer(.success(nil))
            }

            return Disposables.create()
        }
        .subscribe(on: scheduler)
    }

    /// Maps SDK-level errors into the Domain `AuthError` enum.
    /// Network errors → `.network`; HTTP 5xx → `.serviceUnavailable`;
    /// `ASWebAuthenticationSession` cancellation → `.cancelled`.
    static func map(_ error: Error) -> AuthError {
        if let authError = error as? AuthError { return authError }

        #if canImport(AuthenticationServices)
        if let asError = error as? ASWebAuthenticationSessionError,
           asError.code == .canceledLogin {
            return .cancelled
        }
        #endif

        let nsError = error as NSError
        if nsError.domain == NSURLErrorDomain {
            return .network
        }

        if let httpError = error as? HTTPError,
           (500..<600).contains(httpError.response.statusCode) {
            return .serviceUnavailable
        }

        return .unknown(String(describing: type(of: error)))
    }
}
