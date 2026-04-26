import Foundation
import RxSwift

protocol ObserveSessionUseCaseProtocol {
    func execute() -> Observable<AuthState>
}

nonisolated final class ObserveSessionUseCase: ObserveSessionUseCaseProtocol {

    private let repository: AuthRepository

    init(repository: AuthRepository) {
        self.repository = repository
    }

    func execute() -> Observable<AuthState> {
        repository.observe()
    }
}
