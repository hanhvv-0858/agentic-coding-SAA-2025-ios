import Foundation
import RxSwift

protocol SignInWithGoogleUseCaseProtocol {
    func execute() -> Single<AuthSession>
}

/// Orchestrates the full Google OAuth flow with the security ordering
/// required by US2: SDK signIn → email-domain validation → either
/// `acceptSession` (allowed) or `signOut` (disallowed). The Single
/// surfaces `AuthError.disallowedDomain` so the caller can route to
/// Access denied without a transient `.signedIn` flash through `AuthStore`.
nonisolated final class SignInWithGoogleUseCase: SignInWithGoogleUseCaseProtocol {

    private let repository: AuthRepository
    private let checkEmailDomain: CheckEmailDomainUseCaseProtocol

    init(
        repository: AuthRepository,
        checkEmailDomain: CheckEmailDomainUseCaseProtocol
    ) {
        self.repository = repository
        self.checkEmailDomain = checkEmailDomain
    }

    func execute() -> Single<AuthSession> {
        repository.signInWithGoogle()
            .flatMap { [repository, checkEmailDomain] session in
                switch checkEmailDomain.execute(session) {
                case .success(let allowed):
                    return repository.acceptSession(allowed).andThen(.just(allowed))
                case .failure(let error):
                    // Sign out BEFORE surfacing the error so the SDK's
                    // internal session is cleared and the caller can
                    // navigate to Access denied with a clean slate.
                    return repository.signOut()
                        .andThen(Single<AuthSession>.error(error))
                }
            }
    }
}
