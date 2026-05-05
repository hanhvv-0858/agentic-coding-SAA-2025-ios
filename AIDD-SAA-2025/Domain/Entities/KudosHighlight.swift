import Foundation

/// M2 placeholder for the dynamic Kudos banner. M4 may extend this
/// (Q7) to include richer fields (caption, recipient avatar, etc.)
/// when the `kudos_highlights` view ships. For PR-M2.3 the entity is
/// minimal — the M2 banner is bundled, so `bannerImageURL` is `nil`
/// and the View falls back to `Assets.xcassets/KudosBanner`.
struct KudosHighlight: Equatable, Identifiable {
    let id: UUID
    let bannerImageURL: URL?
}

/// State machine for the Kudos banner section (per spec §State Management).
enum KudosBannerState: Equatable {
    case loading
    case loaded(KudosHighlight)
    case empty
}
