import RxBlocking
import RxSwift
import XCTest
@testable import AIDD_SAA_2025

final class FetchHomeFeedUseCaseTests: XCTestCase {

    private final class StubAwards: FetchAwardsUseCaseProtocol {
        var result: Single<[AwardTeaser]> = .just([])
        func execute() -> Single<[AwardTeaser]> { result }
    }
    private final class StubBanner: FetchKudosHighlightUseCaseProtocol {
        var result: Single<KudosHighlight?> = .just(nil)
        func execute() -> Single<KudosHighlight?> { result }
    }

    private func sample() -> AwardTeaser {
        AwardTeaser(
            kind: .mvp,
            titleVI: "MVP", titleEN: "MVP",
            descriptionVI: "vn", descriptionEN: "en",
            artworkAssetKey: "award_mvp",
            displayOrder: 1
        )
    }

    private func makeSUT(
        awards: StubAwards = StubAwards(),
        banner: StubBanner = StubBanner(),
        unread: @escaping () -> Single<Int> = { .just(0) }
    ) -> FetchHomeFeedUseCase {
        FetchHomeFeedUseCase(
            fetchAwards: awards,
            fetchKudosBanner: banner,
            fetchInitialUnreadCount: unread
        )
    }

    // MARK: - Composition

    func test_zip_returnsCombinedFeed() throws {
        let row = sample()
        let highlight = KudosHighlight(id: UUID(), bannerImageURL: nil)
        let awards = StubAwards(); awards.result = .just([row])
        let banner = StubBanner(); banner.result = .just(highlight)
        let sut = makeSUT(awards: awards, banner: banner) { .just(7) }

        let feed = try sut.execute().toBlocking().single()

        XCTAssertEqual(feed.awards, [row])
        XCTAssertEqual(feed.kudosBanner?.id, highlight.id)
        XCTAssertEqual(feed.unreadNotificationCount, 7)
    }

    // MARK: - Partial-failure semantics (per spec FR-009)

    func test_awardsFailure_absorbed_emptyArrayInFeed() throws {
        let awards = StubAwards()
        awards.result = .error(AwardError.unknownKind("x"))
        let sut = makeSUT(awards: awards)

        let feed = try sut.execute().toBlocking().single()
        XCTAssertEqual(feed.awards, [])
    }

    func test_bannerFailure_absorbed_nilInFeed() throws {
        struct BoomError: Error {}
        let banner = StubBanner()
        banner.result = .error(BoomError())
        let sut = makeSUT(banner: banner)

        let feed = try sut.execute().toBlocking().single()
        XCTAssertNil(feed.kudosBanner)
    }

    func test_unreadFailure_absorbed_zeroInFeed() throws {
        struct BoomError: Error {}
        let sut = makeSUT { Single<Int>.error(BoomError()) }

        let feed = try sut.execute().toBlocking().single()
        XCTAssertEqual(feed.unreadNotificationCount, 0)
    }

    func test_negativeUnread_clampedToZero() throws {
        let sut = makeSUT { .just(-3) }
        let feed = try sut.execute().toBlocking().single()
        XCTAssertEqual(feed.unreadNotificationCount, 0)
    }
}
