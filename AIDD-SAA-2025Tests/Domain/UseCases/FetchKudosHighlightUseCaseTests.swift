import RxBlocking
import RxSwift
import XCTest
@testable import AIDD_SAA_2025

final class FetchKudosHighlightUseCaseTests: XCTestCase {

    private final class StubRepository: KudosHighlightRepository {
        var result: Single<KudosHighlight?> = .just(nil)
        func current() -> Single<KudosHighlight?> { result }
    }

    func test_execute_returnsBundledHighlight() throws {
        let repo = StubRepository()
        let highlight = KudosHighlight(id: UUID(), bannerImageURL: nil)
        repo.result = .just(highlight)

        let sut = FetchKudosHighlightUseCase(repository: repo)
        let value = try sut.execute().toBlocking().single()

        XCTAssertEqual(value?.id, highlight.id)
    }

    func test_execute_nilHighlight_isPassedThrough() throws {
        let repo = StubRepository()
        repo.result = .just(nil)

        let sut = FetchKudosHighlightUseCase(repository: repo)
        let value = try sut.execute().toBlocking().single()

        XCTAssertNil(value)
    }
}
