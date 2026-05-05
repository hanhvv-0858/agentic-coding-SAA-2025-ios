import Foundation
import RxSwift

protocol FetchHomeFeedUseCaseProtocol {
    func execute() -> Single<HomeFeed>
}

/// Composes the 3 "on screen load" sources into a single `Single<HomeFeed>`.
/// Per spec §State Management + plan §Architecture:
/// - **Awards** — required for the section to render. If it errors,
///   the caller (`HomeViewModel`) maps to `AwardsTeaserState.error`;
///   here we surface an empty array so the rest of the feed proceeds.
/// - **Kudos banner** — optional. Errors map to `nil` (View renders
///   the bundled fallback / empty-state).
/// - **Initial unread count** — best-effort. Errors clamp to `0`
///   (suppress the dot per US3 AS4).
///
/// This use case never propagates per-section errors via the Single's
/// error channel — those are absorbed inline. The error channel is
/// reserved for cross-cutting failures (auth gone, rare).
nonisolated final class FetchHomeFeedUseCase: FetchHomeFeedUseCaseProtocol {
    private let fetchAwards: FetchAwardsUseCaseProtocol
    private let fetchKudosBanner: FetchKudosHighlightUseCaseProtocol
    private let fetchInitialUnreadCount: () -> Single<Int>

    init(
        fetchAwards: FetchAwardsUseCaseProtocol,
        fetchKudosBanner: FetchKudosHighlightUseCaseProtocol,
        fetchInitialUnreadCount: @escaping () -> Single<Int>
    ) {
        self.fetchAwards = fetchAwards
        self.fetchKudosBanner = fetchKudosBanner
        self.fetchInitialUnreadCount = fetchInitialUnreadCount
    }

    func execute() -> Single<HomeFeed> {
        let awards = fetchAwards.execute()
            .catchAndReturn([])
        let banner = fetchKudosBanner.execute()
            .catchAndReturn(nil)
        let unread = fetchInitialUnreadCount()
            .map { max(0, $0) }
            .catchAndReturn(0)

        return Single.zip(awards, banner, unread) { awardsList, kudosBanner, unreadCount in
            HomeFeed(
                awards: awardsList,
                kudosBanner: kudosBanner,
                unreadNotificationCount: unreadCount
            )
        }
    }
}
