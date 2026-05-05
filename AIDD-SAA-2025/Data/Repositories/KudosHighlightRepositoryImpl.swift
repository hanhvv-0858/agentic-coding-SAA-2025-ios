import Foundation
import RxSwift

/// M2 implementation: returns the bundled-asset placeholder
/// synchronously. The View renders `Assets.xcassets/KudosBanner` when
/// `bannerImageURL` is `nil`, which is always the case here. M4 swaps
/// to a real query against `public.kudos_highlights` (Q7).
nonisolated final class KudosHighlightRepositoryImpl: KudosHighlightRepository {

    /// Stable bundled-banner UUID — matches the asset key. Lets
    /// observers' `distinctUntilChanged` work across re-fetches
    /// without re-rendering.
    private static let bundledBannerID = UUID(
        uuidString: "00000000-0000-0000-0000-00007E4DA1A1"  // "KUDOS" magic
    ) ?? UUID()

    func current() -> Single<KudosHighlight?> {
        .just(KudosHighlight(id: Self.bundledBannerID, bannerImageURL: nil))
    }
}
