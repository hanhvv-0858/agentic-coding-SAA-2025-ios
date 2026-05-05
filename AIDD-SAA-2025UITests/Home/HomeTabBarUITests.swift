import XCTest

/// US8 cold-launch UI test for the bottom tab bar:
/// - Tap each tab → arrive at correct root with that tab highlighted
/// - Re-tap active SAA → ScrollView scrolls to top
/// - Tab-switch latency < 100 ms p95 (`SC-HOME-6`)
///
/// Same launch-arg gap as other Home UI tests. XCTSkipped pending hook.
final class HomeTabBarUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func test_tabBar_rendersExpectedSurface() throws {
        throw XCTSkip("Pending launch-arg hook for direct-to-Home test runs (tasks.md T018 follow-up). T109 covers structural verify via screenshot.")
    }
}
