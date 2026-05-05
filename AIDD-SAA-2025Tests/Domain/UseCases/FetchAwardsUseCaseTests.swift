import RxBlocking
import RxSwift
import XCTest
@testable import AIDD_SAA_2025

final class FetchAwardsUseCaseTests: XCTestCase {

    private final class StubRepository: AwardRepository {
        var result: Single<[AwardTeaser]> = .just([])
        var calls = 0
        func teaser() -> Single<[AwardTeaser]> {
            calls += 1
            return result
        }
    }

    func test_execute_returnsRepositoryRows() throws {
        let repo = StubRepository()
        let row = AwardTeaser(
            kind: .topTalent,
            titleVI: "Top Talent",
            titleEN: "Top Talent",
            descriptionVI: "vn",
            descriptionEN: "en",
            artworkAssetKey: "award_top_talent",
            displayOrder: 6
        )
        repo.result = .just([row])
        let sut = FetchAwardsUseCase(repository: repo)

        let value = try sut.execute().toBlocking().single()

        XCTAssertEqual(value, [row])
        XCTAssertEqual(repo.calls, 1)
    }

    func test_execute_propagatesErrors() {
        let repo = StubRepository()
        repo.result = .error(AwardError.unknownKind("future_kind"))
        let sut = FetchAwardsUseCase(repository: repo)

        XCTAssertThrowsError(try sut.execute().toBlocking().single()) { err in
            XCTAssertEqual(err as? AwardError, .unknownKind("future_kind"))
        }
    }

    func test_execute_emptyArray_isPassedThrough() throws {
        let repo = StubRepository()
        repo.result = .just([])
        let sut = FetchAwardsUseCase(repository: repo)

        let value = try sut.execute().toBlocking().single()
        XCTAssertEqual(value, [])
    }
}
