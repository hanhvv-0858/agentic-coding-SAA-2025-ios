import Foundation
import RxSwift

protocol FetchKudosHighlightUseCaseProtocol {
    func execute() -> Single<KudosHighlight?>
}

nonisolated final class FetchKudosHighlightUseCase: FetchKudosHighlightUseCaseProtocol {
    private let repository: KudosHighlightRepository

    init(repository: KudosHighlightRepository) {
        self.repository = repository
    }

    func execute() -> Single<KudosHighlight?> {
        repository.current()
    }
}
