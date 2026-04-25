import XCTest
@testable import AIDD_SAA_2025

final class LocaleStoreTests: XCTestCase {

    private func makeStorage() -> UserDefaults {
        let suiteName = "test.locale.\(UUID().uuidString)"
        let storage = UserDefaults(suiteName: suiteName)!
        storage.removePersistentDomain(forName: suiteName)
        return storage
    }

    func test_initialValue_fallsBackToDefault() {
        let storage = makeStorage()
        let store = LocaleStore(storage: storage, storageKey: "appLanguage")
        XCTAssertTrue(AppLanguage.allCases.contains(store.language.value))
    }

    func test_set_persistsToStorage() {
        let storage = makeStorage()
        let store = LocaleStore(storage: storage, storageKey: "appLanguage")

        store.set(.vi)

        XCTAssertEqual(store.language.value, .vi)
        XCTAssertEqual(storage.string(forKey: "appLanguage"), "vi")
    }

    func test_init_restoresStoredValue() {
        let storage = makeStorage()
        storage.set("en", forKey: "appLanguage")

        let store = LocaleStore(storage: storage, storageKey: "appLanguage")

        XCTAssertEqual(store.language.value, .en)
    }

    func test_set_isIdempotent() {
        let storage = makeStorage()
        let store = LocaleStore(storage: storage, storageKey: "appLanguage")
        store.set(.vi)
        store.set(.vi)
        XCTAssertEqual(store.language.value, .vi)
    }
}
