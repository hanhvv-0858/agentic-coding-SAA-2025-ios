import RxBlocking
import RxSwift
import XCTest
@testable import AIDD_SAA_2025

final class AwardRepositoryImplTests: XCTestCase {

    private final class StubDataSource: AwardRemoteDataSource {
        var result: Single<[AwardDTO]> = .just([])
        func fetchTeaser() -> Single<[AwardDTO]> { result }
    }

    private func dto(
        kind: String = "top_talent",
        order: Int = 6
    ) -> AwardDTO {
        AwardDTO(
            kind: kind,
            titleVi: "Top Talent",
            titleEn: "Top Talent",
            descriptionVi: "vn",
            descriptionEn: "en",
            artworkAssetKey: "award_top_talent",
            displayOrder: order
        )
    }

    // MARK: - Happy path

    func test_teaser_mapsDTOsToDomain() throws {
        let ds = StubDataSource()
        ds.result = .just([dto(kind: "top_talent", order: 6)])
        let sut = AwardRepositoryImpl(dataSource: ds)

        let rows = try sut.teaser().toBlocking().single()

        XCTAssertEqual(rows.count, 1)
        XCTAssertEqual(rows[0].kind, .topTalent)
        XCTAssertEqual(rows[0].displayOrder, 6)
        XCTAssertEqual(rows[0].artworkAssetKey, "award_top_talent")
    }

    // MARK: - Validation

    func test_teaser_unknownKind_surfacesAwardError() {
        let ds = StubDataSource()
        ds.result = .just([dto(kind: "future_kind_not_in_enum", order: 7)])
        let sut = AwardRepositoryImpl(dataSource: ds)

        XCTAssertThrowsError(try sut.teaser().toBlocking().single()) { err in
            XCTAssertEqual(err as? AwardError, .unknownKind("future_kind_not_in_enum"))
        }
    }

    // MARK: - Transport errors

    func test_teaser_5xx_propagatesError() {
        struct HTTP5xx: Error {}
        let ds = StubDataSource()
        ds.result = .error(HTTP5xx())
        let sut = AwardRepositoryImpl(dataSource: ds)

        XCTAssertThrowsError(try sut.teaser().toBlocking().single()) { err in
            XCTAssertTrue(err is HTTP5xx)
        }
    }

    // MARK: - Empty

    func test_teaser_emptyArray_returnsEmpty() throws {
        let ds = StubDataSource()
        ds.result = .just([])
        let sut = AwardRepositoryImpl(dataSource: ds)

        let rows = try sut.teaser().toBlocking().single()
        XCTAssertEqual(rows, [])
    }
}
