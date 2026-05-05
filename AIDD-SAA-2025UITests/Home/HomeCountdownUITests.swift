import XCTest

/// US1 cold-launch UI test. Asserts the rendered HomeView surfaces:
/// - Header (search + bell buttons reachable via accessibility ids)
/// - Countdown digits + "Coming soon" hide/show per Q1 resolution
/// - Event-info copy + ABOUT buttons + theme paragraph
///
/// Note: launching directly into Home requires a launch-flag hook
/// (see [tasks.md T018](../../.momorph/specs/OuH1BUTYT0-home/tasks.md))
/// that is not yet wired. Until that lands, this test launches the app
/// (lands on Login) and only verifies that the build can boot without
/// crashing — the screen-level assertions are gated as XCTSkip pending
/// the hook. The structural checklist below is what T103b covers
/// manually via screenshot comparison.
final class HomeCountdownUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func test_appLaunches_withoutCrashing() throws {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.state == .runningForeground)
    }

    /// Skipped until a launch flag like `-StartRoute home` lands. T103b
    /// performs this verification manually via screenshot.
    func test_homeView_rendersExpectedSurface() throws {
        throw XCTSkip("Pending launch-arg hook for direct-to-Home test runs (tasks.md T018 follow-up). T103b covers this manually via screenshot.")
    }
}
