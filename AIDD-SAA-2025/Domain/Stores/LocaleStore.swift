import Foundation
import RxRelay
import RxSwift

protocol LocaleStoring: AnyObject {
    var language: BehaviorRelay<AppLanguage> { get }
    var languageObservable: Observable<AppLanguage> { get }
    func set(_ language: AppLanguage)
}

nonisolated final class LocaleStore: LocaleStoring {
    let language: BehaviorRelay<AppLanguage>

    var languageObservable: Observable<AppLanguage> {
        language.asObservable().distinctUntilChanged()
    }

    private let storage: UserDefaults
    private let storageKey: String

    init(storage: UserDefaults = .standard, storageKey: String = "appLanguage") {
        self.storage = storage
        self.storageKey = storageKey

        let stored = storage.string(forKey: storageKey).flatMap(AppLanguage.init(rawValue:))
        self.language = BehaviorRelay(value: stored ?? AppLanguage.default)
    }

    func set(_ language: AppLanguage) {
        guard self.language.value != language else { return }
        storage.set(language.rawValue, forKey: storageKey)
        self.language.accept(language)
    }
}
