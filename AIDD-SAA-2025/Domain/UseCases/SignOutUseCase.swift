import Foundation
import RxSwift

protocol SignOutUseCaseProtocol {
    func execute() -> Completable
}

nonisolated final class SignOutUseCase: SignOutUseCaseProtocol {

    private let repository: AuthRepository

    init(repository: AuthRepository) {
        self.repository = repository
    }

    func execute() -> Completable {
        repository.signOut()
    }
}
