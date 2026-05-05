import XCTest

/// US4 cold-launch UI test for the FAB:
/// - Pen tap → ComingSoonPlaceholder(.compose) reachable
/// - S tap → ComingSoonPlaceholder(.kudosFeed) reachable
/// - Double-tap pen → only one navigation push (debounce + in-flight guard)
/// - Navigate away + back → both zones tap-receptive again (US4 AS5)
///
/// Same launch-arg gap as `HomeCountdownUITests`. XCTSkipped until
/// the launch hook lands; T106b covers structural verify via screenshot.
final class HomeFABUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func test_fab_rendersExpectedSurface() throws {
        throw XCTSkip("Pending launch-arg hook for direct-to-Home test runs (tasks.md T018 / T070 follow-up). T106b covers structural verify via screenshot.")
    }
}
