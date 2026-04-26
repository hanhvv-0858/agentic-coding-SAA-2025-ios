import Foundation

protocol SetAppLanguageUseCaseProtocol {
    func execute(_ language: AppLanguage)
}

/// Thin wrapper around `LocaleStore.set` — kept as its own use case so
/// the Login VM can inject a protocol and so the idempotency contract
/// (US3 AS5: setting the current language must not re-emit) lives in
/// one testable place.
nonisolated final class SetAppLanguageUseCase: SetAppLanguageUseCaseProtocol {

    private let localeStore: LocaleStoring

    init(localeStore: LocaleStoring) {
        self.localeStore = localeStore
    }

    func execute(_ language: AppLanguage) {
        localeStore.set(language)
    }
}
