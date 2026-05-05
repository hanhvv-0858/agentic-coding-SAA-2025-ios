import XCTest

/// US2 cold-launch UI test for the Awards section. Asserts that the
/// rendered HomeView surfaces:
/// - Awards section header ("Sun* Annual Awards 2025" / "Hệ thống giải thưởng")
/// - Horizontal scroll of `AwardCardView`s with at least 3 visible
/// - Tap "Chi tiết" on a card → `AwardDetailPlaceholder` for that kind
/// - ABOUT AWARD hero CTA scrolls the section into view
/// - Empty + error states render the right copy
///
/// Same gap as `HomeCountdownUITests`: launching directly into Home
/// requires a launch-flag hook (T018 follow-up). Until that lands the
/// screen-level assertions are XCTSkipped — T104b covers the
/// structural verification manually via screenshot.
final class HomeAwardsUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func test_awardsSection_rendersExpectedSurface() throws {
        throw XCTSkip("Pending launch-arg hook for direct-to-Home test runs (tasks.md T018 follow-up). T104b covers this manually via screenshot.")
    }
}
