import XCTest
@testable import AIDD_SAA_2025

final class FirstLaunchDetectorTests: XCTestCase {

    private func makeStorage() -> UserDefaults {
        let suiteName = "test.first-launch.\(UUID().uuidString)"
        let storage = UserDefaults(suiteName: suiteName)!
        storage.removePersistentDomain(forName: suiteName)
        return storage
    }

    func test_firstCall_returnsTrue() {
        let sut = UserDefaultsFirstLaunchDetector(storage: makeStorage(), key: "k")

        XCTAssertTrue(sut.consumeFirstLaunch())
    }

    func test_secondCall_returnsFalse() {
        let storage = makeStorage()
        let sut = UserDefaultsFirstLaunchDetector(storage: storage, key: "k")
        _ = sut.consumeFirstLaunch()

        XCTAssertFalse(sut.consumeFirstLaunch())
    }

    /// Simulates the install→delete→reinstall lifecycle: deleting the
    /// app wipes UserDefaults (modeled here by clearing the suite),
    /// so the next launch must look "fresh" again.
    func test_afterStorageWipe_returnsTrueAgain() {
        let storage = makeStorage()
        let key = "k"

        let first = UserDefaultsFirstLaunchDetector(storage: storage, key: key)
        _ = first.consumeFirstLaunch()
        XCTAssertFalse(first.consumeFirstLaunch())

        // Simulate "delete app" — UserDefaults goes away.
        storage.removeObject(forKey: key)

        let afterReinstall = UserDefaultsFirstLaunchDetector(storage: storage, key: key)
        XCTAssertTrue(afterReinstall.consumeFirstLaunch())
    }

    func test_persistedFlag_survivesAcrossInstances_withinSameInstall() {
        let storage = makeStorage()
        let key = "k"

        _ = UserDefaultsFirstLaunchDetector(storage: storage, key: key).consumeFirstLaunch()

        let secondInstance = UserDefaultsFirstLaunchDetector(storage: storage, key: key)
        XCTAssertFalse(secondInstance.consumeFirstLaunch())
    }
}
