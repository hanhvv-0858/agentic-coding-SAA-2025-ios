import Foundation
import RxSwift

/// Read-only access to the `public.awards` catalogue. M2 surface is
/// the Home teaser (`teaser()`); M4 may extend with `detail(kind:)`
/// for the full Award detail view.
protocol AwardRepository: AnyObject {
    /// Returns the full ordered award catalogue, capped at 6 rows
    /// (per spec §API Requirements `.limit(6)`). Errors are bubbled
    /// up — the calling use case maps them to the `AwardsTeaserState`
    /// `.error` case.
    func teaser() -> Single<[AwardTeaser]>
}

/// Domain-level errors emitted by `AwardRepository` impls.
enum AwardError: Error, Equatable {
    /// The DTO mapper saw a `kind` value that's not in
    /// `AwardKind.allCases` — likely a 7th category was added to the
    /// DB without a matching Swift enum case. Fail loud rather than
    /// silently dropping rows.
    case unknownKind(String)
}
