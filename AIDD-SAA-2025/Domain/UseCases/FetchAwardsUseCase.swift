import Foundation
import RxSwift

protocol FetchAwardsUseCaseProtocol {
    func execute() -> Single<[AwardTeaser]>
}

/// Thin wrapper around `AwardRepository.teaser()`. Kept as its own
/// type so the future Awards-tab list view can call it directly
/// without going through `FetchHomeFeedUseCase`.
nonisolated final class FetchAwardsUseCase: FetchAwardsUseCaseProtocol {
    private let repository: AwardRepository

    init(repository: AwardRepository) {
        self.repository = repository
    }

    func execute() -> Single<[AwardTeaser]> {
        repository.teaser()
    }
}
