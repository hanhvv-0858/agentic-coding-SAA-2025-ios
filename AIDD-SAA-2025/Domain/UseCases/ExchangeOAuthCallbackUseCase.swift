import Foundation
import RxSwift

protocol ExchangeOAuthCallbackUseCaseProtocol {
    func execute(url: URL) -> Single<AuthSession>
}

/// Same orchestration as `SignInWithGoogleUseCase` but starting from a
/// deep-link callback URL instead of a fresh OAuth tap.
nonisolated final class ExchangeOAuthCallbackUseCase: ExchangeOAuthCallbackUseCaseProtocol {

    private let repository: AuthRepository
    private let checkEmailDomain: CheckEmailDomainUseCaseProtocol

    init(
        repository: AuthRepository,
        checkEmailDomain: CheckEmailDomainUseCaseProtocol
    ) {
        self.repository = repository
        self.checkEmailDomain = checkEmailDomain
    }

    func execute(url: URL) -> Single<AuthSession> {
        repository.exchangeCallback(url)
            .flatMap { [repository, checkEmailDomain] session in
                switch checkEmailDomain.execute(session) {
                case .success(let allowed):
                    return repository.acceptSession(allowed).andThen(.just(allowed))
                case .failure(let error):
                    return repository.signOut()
                        .andThen(Single<AuthSession>.error(error))
                }
            }
    }
}
