import Foundation
import RxSwift

protocol RestoreSessionUseCaseProtocol {
    func execute() -> Single<AuthState>
}

nonisolated final class RestoreSessionUseCase: RestoreSessionUseCaseProtocol {

    private let repository: AuthRepository

    init(repository: AuthRepository) {
        self.repository = repository
    }

    func execute() -> Single<AuthState> {
        repository.restoreSession()
    }
}
