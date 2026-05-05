import XCTest

/// US5 cold-launch UI test for the Language switcher on Home:
/// - Tap chip → dropdown overlay appears under the chip
/// - Tap alternate language → labels swap; dropdown dismisses
/// - Pick currently-selected language → dropdown dismisses but no
///   re-render churn (LocaleStore.set is idempotent)
/// - Selection persists across app relaunches
///
/// Same launch-arg gap as other Home UI tests. XCTSkipped until the
/// launch hook lands; T107 covers structural verify via screenshot.
final class HomeLanguageUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func test_languageSwitcher_rendersExpectedSurface() throws {
        throw XCTSkip("Pending launch-arg hook for direct-to-Home test runs (tasks.md T018 follow-up). T107 covers structural verify via screenshot.")
    }
}
