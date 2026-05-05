import XCTest

/// US7 cold-launch UI test for the header search icon:
/// - Tap search → ComingSoonPlaceholder(.search) reachable + back works
///
/// Same launch-arg gap as other Home UI tests. XCTSkipped pending hook.
final class HomeSearchUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func test_searchIcon_navigatesToSearchPlaceholder() throws {
        throw XCTSkip("Pending launch-arg hook for direct-to-Home test runs.")
    }
}
