import XCTest

/// US6 cold-launch UI test for pull-to-refresh:
/// - Pull at top → indicator visible → resolves within `SC-HOME-4` budget (1.5 s p95)
/// - Awards-only failure → indicator dismisses, kudos updates, awards section retry row
///
/// Same launch-arg gap as other Home UI tests. XCTSkipped pending hook.
final class HomeRefreshUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func test_pullToRefresh_rendersExpectedSurface() throws {
        throw XCTSkip("Pending launch-arg hook for direct-to-Home test runs (tasks.md T018 follow-up).")
    }
}
