import Foundation
import RxSwift

/// Source for the Kudos banner shown on Home. M2 returns a bundled
/// placeholder synchronously (Q7 default); M4 may swap to a real
/// query against the `kudos_highlights` view.
protocol KudosHighlightRepository: AnyObject {
    /// Returns the current Kudos highlight, or `nil` if there's
    /// nothing to show (Home renders empty state — never blocks
    /// the page).
    func current() -> Single<KudosHighlight?>
}
