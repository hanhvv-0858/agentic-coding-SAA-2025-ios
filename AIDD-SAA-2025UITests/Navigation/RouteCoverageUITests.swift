import XCTest

/// Asserts that PR-M2.1's exhaustive switch on `AppRoute` is in place —
/// every route case must resolve to a concrete view, not a Login
/// fall-through. The Swift compiler enforces case exhaustiveness
/// statically (RootView's switch has no `default` branch), so this
/// test is the runtime smoke complement.
///
/// The current test only covers the launch route (`.login`). Once a
/// launch-argument hook for setting an arbitrary AppRoute lands (e.g.
/// `-StartRoute home` consumed by `Container.bootstrap`), this file
/// expands to cover every authenticated route by launching with each
/// in turn and asserting the BottomTabBar is present.
///
/// See [tasks.md T018](../../.momorph/specs/OuH1BUTYT0-home/tasks.md#L33)
/// for the future expansion list.
final class RouteCoverageUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func test_launch_landsOnLogin() throws {
        let app = XCUIApplication()
        app.launch()

        // LoginView mounts a sign-in CTA via accessibilityIdentifier.
        let signInButton = app.buttons["LoginView.signInButton"]
        XCTAssertTrue(signInButton.waitForExistence(timeout: 5), "Login screen must be visible at launch")
    }
}
