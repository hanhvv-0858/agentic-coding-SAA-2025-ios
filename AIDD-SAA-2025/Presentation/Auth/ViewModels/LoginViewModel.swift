import Foundation
import RxCocoa
import RxRelay
import RxSwift
import os

protocol LoginViewModel: AnyObject {
    // Inputs
    var signInTapped: PublishRelay<Void> { get }
    var languageTapped: PublishRelay<Void> { get }
    var languageSelected: PublishRelay<AppLanguage> { get }
    var oauthCallback: PublishRelay<URL> { get }
    var viewAppeared: PublishRelay<Void> { get }

    // Outputs
    var isLoading: Driver<Bool> { get }
    var selectedLanguage: Driver<AppLanguage> { get }
    var errorMessage: Signal<String> { get }
    var navigateHome: Signal<Void> { get }
    var navigateAccessDenied: Signal<Void> { get }
    var presentLanguageSheet: Signal<Void> { get }
}

nonisolated final class LoginViewModelImpl: LoginViewModel {

    // MARK: Inputs
    let signInTapped = PublishRelay<Void>()
    let languageTapped = PublishRelay<Void>()
    let languageSelected = PublishRelay<AppLanguage>()
    let oauthCallback = PublishRelay<URL>()
    let viewAppeared = PublishRelay<Void>()

    // MARK: Outputs
    var isLoading: Driver<Bool> { isLoadingRelay.asDriver() }
    var selectedLanguage: Driver<AppLanguage> { localeStore.language.asDriver() }
    var errorMessage: Signal<String> { errorMessageRelay.asSignal() }
    var navigateHome: Signal<Void> { navigateHomeRelay.asSignal() }
    var navigateAccessDenied: Signal<Void> { navigateAccessDeniedRelay.asSignal() }
    var presentLanguageSheet: Signal<Void> { presentLanguageSheetRelay.asSignal() }

    private let isLoadingRelay = BehaviorRelay<Bool>(value: false)
    private let errorMessageRelay = PublishRelay<String>()
    private let navigateHomeRelay = PublishRelay<Void>()
    private let navigateAccessDeniedRelay = PublishRelay<Void>()
    private let presentLanguageSheetRelay = PublishRelay<Void>()

    private let signInUseCase: SignInWithGoogleUseCaseProtocol
    private let exchangeCallbackUseCase: ExchangeOAuthCallbackUseCaseProtocol
    private let setAppLanguageUseCase: SetAppLanguageUseCaseProtocol
    private let localeStore: LocaleStoring
    private let analytics: AnalyticsClient
    private let disposeBag = DisposeBag()

    init(
        signInUseCase: SignInWithGoogleUseCaseProtocol,
        exchangeCallbackUseCase: ExchangeOAuthCallbackUseCaseProtocol,
        setAppLanguageUseCase: SetAppLanguageUseCaseProtocol,
        localeStore: LocaleStoring,
        analytics: AnalyticsClient
    ) {
        self.signInUseCase = signInUseCase
        self.exchangeCallbackUseCase = exchangeCallbackUseCase
        self.setAppLanguageUseCase = setAppLanguageUseCase
        self.localeStore = localeStore
        self.analytics = analytics

        bind()
    }

    private func bind() {
        // Spec: rapid double-taps must not start two OAuth sessions.
        // `startSignIn` flips `isLoading` synchronously, so the
        // `withLatestFrom + filter` pair gates further taps until the
        // current attempt resolves (success / cancel / error) and flips
        // it back to false.
        viewAppeared
            .subscribe(onNext: { [analytics] _ in analytics.track(.loginViewed) })
            .disposed(by: disposeBag)

        signInTapped
            .withLatestFrom(isLoadingRelay)
            .filter { isLoading in !isLoading }
            .subscribe(onNext: { [weak self] _ in
                self?.analytics.track(.loginGoogleTapped)
                self?.startSignIn()
            })
            .disposed(by: disposeBag)

        languageTapped
            .bind(to: presentLanguageSheetRelay)
            .disposed(by: disposeBag)

        // US3: forward sheet selection to the use case. LocaleStore.set
        // is idempotent — selecting the current language is a no-op
        // and does NOT re-emit (verified by SetAppLanguageUseCaseTests).
        languageSelected
            .subscribe(onNext: { [setAppLanguageUseCase] in
                setAppLanguageUseCase.execute($0)
            })
            .disposed(by: disposeBag)

        oauthCallback
            .subscribe(onNext: { [weak self] url in self?.handleCallback(url) })
            .disposed(by: disposeBag)
    }

    private func startSignIn() {
        isLoadingRelay.accept(true)

        signInUseCase.execute()
            .subscribe(
                onSuccess: { [weak self] session in
                    guard let self else { return }
                    self.isLoadingRelay.accept(false)
                    self.analytics.track(.loginSuccess)
                    self.navigateHomeRelay.accept(())
                    _ = session // intentionally unused — never logged
                },
                onFailure: { [weak self] error in
                    self?.handle(error: error)
                }
            )
            .disposed(by: disposeBag)
    }

    private func handleCallback(_ url: URL) {
        exchangeCallbackUseCase.execute(url: url)
            .subscribe(
                onSuccess: { [weak self] _ in
                    guard let self else { return }
                    self.isLoadingRelay.accept(false)
                    self.analytics.track(.loginSuccess)
                    self.navigateHomeRelay.accept(())
                },
                onFailure: { [weak self] error in
                    self?.handle(error: error)
                }
            )
            .disposed(by: disposeBag)
    }

    private func handle(error: Error) {
        isLoadingRelay.accept(false)

        let authError = (error as? AuthError) ?? .unknown(String(describing: error))
        switch authError {
        case .cancelled:
            // Silent: spec US1 AS2 — no toast, button re-enabled. Don't
            // emit an analytics event either; user-initiated cancellation
            // is not actionable signal.
            return
        case .disallowedDomain:
            // US2: signIn use case has already invoked signOut; route to
            // Access denied. We have no email to read here on purpose
            // (the SignIn use case discarded the session); analytics
            // emits a generic `denied` event without a domain so we
            // never risk a PII leak through this branch. A richer
            // event with `email_domain` can be added in M2 once the
            // domain is plumbed through the error type.
            analytics.track(.loginDenied(emailDomain: ""))
            navigateAccessDeniedRelay.accept(())
        default:
            analytics.track(.loginError(code: authError.analyticsCode))
            if let message = authError.errorDescription, !message.isEmpty {
                errorMessageRelay.accept(message)
            }
        }
    }
}

private extension AuthError {
    /// Stable code emitted to analytics. Never carries the raw error
    /// description (which may include URL paths or upstream messages).
    var analyticsCode: String {
        switch self {
        case .cancelled:          return "cancelled"
        case .network:            return "network"
        case .disallowedDomain:   return "disallowed_domain"
        case .serviceUnavailable: return "service_unavailable"
        case .unknown:            return "unknown"
        }
    }
}
