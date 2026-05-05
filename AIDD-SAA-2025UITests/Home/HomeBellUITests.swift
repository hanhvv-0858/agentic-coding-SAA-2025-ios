import XCTest

/// US3 cold-launch UI test for the Bell + UnreadDotBadge:
/// - With seeded unread row → bell-dot is visible
/// - Mark-all-read via SQL → Realtime emits → dot disappears
/// - Mid-session HEAD failure → dot retains last good value
///
/// Same launch-arg gap as `HomeCountdownUITests` / `HomeAwardsUITests`.
/// XCTSkipped until the launch hook lands; T105 covers structural
/// verification manually via screenshot.
final class HomeBellUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func test_bellDot_rendersExpectedSurface() throws {
        throw XCTSkip("Pending launch-arg hook for direct-to-Home + seeded-notifications test runs (tasks.md T018 / T070 follow-up). T105 covers structural verify via screenshot.")
    }
}
