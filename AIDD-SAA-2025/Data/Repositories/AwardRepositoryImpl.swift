import Foundation
import RxSwift

/// Maps DTOs from the data source into domain entities. Logs `kind`
/// values only at `.public` privacy (no PII risk — these are well-known
/// award identifiers from the DB enum).
nonisolated final class AwardRepositoryImpl: AwardRepository {

    private let dataSource: AwardRemoteDataSource

    init(dataSource: AwardRemoteDataSource) {
        self.dataSource = dataSource
    }

    func teaser() -> Single<[AwardTeaser]> {
        dataSource.fetchTeaser()
            .map { dtos in
                try dtos.map { try $0.toDomain() }
            }
    }
}
