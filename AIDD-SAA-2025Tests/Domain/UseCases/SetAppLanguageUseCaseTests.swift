import RxRelay
import RxSwift
import XCTest
@testable import AIDD_SAA_2025

final class SetAppLanguageUseCaseTests: XCTestCase {

    private func makeStorage() -> UserDefaults {
        let suiteName = "test.set-lang.\(UUID().uuidString)"
        let storage = UserDefaults(suiteName: suiteName)!
        storage.removePersistentDomain(forName: suiteName)
        return storage
    }

    func test_execute_persistsToLocaleStore() {
        let store = LocaleStore(storage: makeStorage(), storageKey: "appLanguage")
        let sut = SetAppLanguageUseCase(localeStore: store)

        sut.execute(.vi)

        XCTAssertEqual(store.language.value, .vi)
    }

    /// US3 AS5: tapping the row of the *currently selected* language
    /// must NOT emit a `.next` to subscribers — otherwise the entire
    /// app would re-render for nothing.
    func test_execute_idempotent_setsCurrentLanguage_doesNotReEmit() {
        let store = LocaleStore(storage: makeStorage(), storageKey: "appLanguage")
        store.set(.vi)

        var emissions: [AppLanguage] = []
        let bag = DisposeBag()
        store.languageObservable
            .skip(1) // skip the BehaviorRelay's initial replay
            .subscribe(onNext: { emissions.append($0) })
            .disposed(by: bag)

        let sut = SetAppLanguageUseCase(localeStore: store)
        sut.execute(.vi) // already .vi — should be a no-op

        XCTAssertTrue(emissions.isEmpty, "Setting the current language must not emit")
    }

    func test_execute_distinctValue_doesEmit() {
        let store = LocaleStore(storage: makeStorage(), storageKey: "appLanguage")
        store.set(.vi)

        var emissions: [AppLanguage] = []
        let bag = DisposeBag()
        store.languageObservable
            .skip(1)
            .subscribe(onNext: { emissions.append($0) })
            .disposed(by: bag)

        let sut = SetAppLanguageUseCase(localeStore: store)
        sut.execute(.en)

        XCTAssertEqual(emissions, [.en])
    }
}
