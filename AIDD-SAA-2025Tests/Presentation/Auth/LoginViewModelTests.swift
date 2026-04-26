import RxBlocking
import RxCocoa
import RxRelay
import RxSwift
import RxTest
import XCTest
@testable import AIDD_SAA_2025

final class LoginViewModelTests: XCTestCase {

    private var repository: MockAuthRepository!
    private var localeStore: LocaleStore!
    private var analytics: MockAnalyticsClient!
    private var disposeBag: DisposeBag!

    override func setUp() {
        super.setUp()
        repository = MockAuthRepository()
        localeStore = LocaleStore(
            storage: UserDefaults(suiteName: "test.login.\(UUID().uuidString)")!,
            storageKey: "appLanguage"
        )
        analytics = MockAnalyticsClient()
        disposeBag = DisposeBag()
    }

    override func tearDown() {
        disposeBag = nil
        analytics = nil
        localeStore = nil
        repository = nil
        super.tearDown()
    }

    private let allowlist = AllowedEmailDomains(domains: ["sun-asterisk.com"])

    private func makeSUT() -> LoginViewModelImpl {
        let checkDomain = CheckEmailDomainUseCase(allowlist: allowlist)
        return LoginViewModelImpl(
            signInUseCase: SignInWithGoogleUseCase(
                repository: repository,
                checkEmailDomain: checkDomain
            ),
            exchangeCallbackUseCase: ExchangeOAuthCallbackUseCase(
                repository: repository,
                checkEmailDomain: checkDomain
            ),
            setAppLanguageUseCase: SetAppLanguageUseCase(localeStore: localeStore),
            localeStore: localeStore,
            analytics: analytics
        )
    }

    private func collect<T>(_ source: Observable<T>) -> () -> [T] {
        var collected: [T] = []
        source.subscribe(onNext: { collected.append($0) }).disposed(by: disposeBag)
        return { collected }
    }

    // MARK: - Happy path

    func test_signInTapped_success_setsLoadingThenNavigatesHome() {
        let session = AuthSessionFixture.make()
        repository.signInResult = .just(session)
        let sut = makeSUT()

        let loadingStates = collect(sut.isLoading.asObservable())
        let navigations = collect(sut.navigateHome.asObservable())

        sut.signInTapped.accept(())

        XCTAssertEqual(loadingStates(), [false, true, false])
        XCTAssertEqual(navigations().count, 1)
        XCTAssertEqual(repository.signInCalls, 1)
    }

    // MARK: - Cancellation is silent

    func test_signInTapped_userCancelled_isSilentAndStopsLoading() {
        repository.signInResult = .error(AuthError.cancelled)
        let sut = makeSUT()

        let loadingStates = collect(sut.isLoading.asObservable())
        let errors = collect(sut.errorMessage.asObservable())
        let navigations = collect(sut.navigateHome.asObservable())

        sut.signInTapped.accept(())

        XCTAssertEqual(loadingStates(), [false, true, false])
        XCTAssertTrue(errors().isEmpty, "Cancellation must NOT surface an alert")
        XCTAssertTrue(navigations().isEmpty)
    }

    // MARK: - Network error

    func test_signInTapped_networkError_emitsErrorMessageAndStopsLoading() {
        repository.signInResult = .error(AuthError.network)
        let sut = makeSUT()

        let loadingStates = collect(sut.isLoading.asObservable())
        let errors = collect(sut.errorMessage.asObservable())

        sut.signInTapped.accept(())

        XCTAssertEqual(loadingStates(), [false, true, false])
        XCTAssertEqual(errors().count, 1)
        XCTAssertFalse(errors().first?.isEmpty ?? true)
    }

    func test_signInTapped_serviceUnavailable_emitsErrorMessage() {
        repository.signInResult = .error(AuthError.serviceUnavailable)
        let sut = makeSUT()

        let errors = collect(sut.errorMessage.asObservable())
        sut.signInTapped.accept(())

        XCTAssertEqual(errors().count, 1)
    }

    // MARK: - Disallowed domain (US2)

    func test_signInTapped_disallowedDomain_emitsNavigateAccessDenied_andNoErrorMessage() {
        // Domain is rejected by CheckEmailDomain → SignInUseCase invokes
        // repo.signOut() and surfaces .disallowedDomain → VM routes to
        // Access denied without showing an alert.
        let session = AuthSessionFixture.make(email: "bob@gmail.com")
        repository.signInResult = .just(session)
        let sut = makeSUT()

        let navigations = collect(sut.navigateAccessDenied.asObservable())
        let homeNavigations = collect(sut.navigateHome.asObservable())
        let errors = collect(sut.errorMessage.asObservable())
        let loadingStates = collect(sut.isLoading.asObservable())

        sut.signInTapped.accept(())

        XCTAssertEqual(navigations().count, 1)
        XCTAssertTrue(homeNavigations().isEmpty)
        XCTAssertTrue(errors().isEmpty)
        XCTAssertEqual(loadingStates(), [false, true, false])
        XCTAssertEqual(repository.signOutCalls, 1)
        XCTAssertTrue(repository.acceptedSessions.isEmpty)
    }

    // MARK: - Double-tap debounce

    func test_signInTapped_doubleTapWhileLoading_triggersOnlyOneSignIn() {
        // Block the result so the VM stays in `isLoading == true`,
        // emulating an in-flight OAuth web sheet. A second tap during
        // that window must be ignored — both by the in-flight guard
        // and by the 300 ms throttle.
        repository.signInResult = .never()
        let sut = makeSUT()

        sut.signInTapped.accept(())
        sut.signInTapped.accept(())
        sut.signInTapped.accept(())

        XCTAssertEqual(repository.signInCalls, 1)
    }

    // MARK: - Language tap

    func test_languageTapped_emitsPresentLanguageSheet() {
        let sut = makeSUT()
        let presentations = collect(sut.presentLanguageSheet.asObservable())

        sut.languageTapped.accept(())

        XCTAssertEqual(presentations().count, 1)
    }

    func test_selectedLanguage_initiallyMatchesLocaleStore() {
        let sut = makeSUT()
        let collected = collect(sut.selectedLanguage.asObservable())

        XCTAssertEqual(collected().last, localeStore.language.value)
    }

    // MARK: - oauthCallback

    // MARK: - Analytics (Phase 7 / T072)

    func test_viewAppeared_emitsLoginViewedEvent() {
        let sut = makeSUT()

        sut.viewAppeared.accept(())

        XCTAssertEqual(analytics.tracked, [.loginViewed])
    }

    func test_signInTapped_success_emitsTappedThenSuccess() {
        repository.signInResult = .just(AuthSessionFixture.make())
        let sut = makeSUT()

        sut.signInTapped.accept(())

        XCTAssertEqual(analytics.tracked, [.loginGoogleTapped, .loginSuccess])
    }

    func test_signInTapped_disallowedDomain_emitsTappedThenDenied_neverIncludesEmail() {
        repository.signInResult = .just(AuthSessionFixture.make(email: "bob@gmail.com"))
        let sut = makeSUT()

        sut.signInTapped.accept(())

        XCTAssertEqual(analytics.tracked.count, 2)
        XCTAssertEqual(analytics.tracked.first, .loginGoogleTapped)
        // Spec §Analytics: never log full email. We currently emit
        // an empty domain (the SignIn use case discards the session
        // before surfacing .disallowedDomain) — the important
        // invariant is that no `@` ever reaches the analytics layer.
        if case .loginDenied(let domain) = analytics.tracked.last {
            XCTAssertFalse(domain.contains("@"))
        } else {
            XCTFail("Expected .loginDenied as last event")
        }
    }

    func test_signInTapped_networkError_emitsTappedThenError() {
        repository.signInResult = .error(AuthError.network)
        let sut = makeSUT()

        sut.signInTapped.accept(())

        XCTAssertEqual(analytics.tracked, [.loginGoogleTapped, .loginError(code: "network")])
    }

    func test_signInTapped_cancelled_emitsTappedOnly_noFollowUpEvent() {
        // User-initiated cancellation isn't actionable signal — skip it.
        repository.signInResult = .error(AuthError.cancelled)
        let sut = makeSUT()

        sut.signInTapped.accept(())

        XCTAssertEqual(analytics.tracked, [.loginGoogleTapped])
    }

    // MARK: - US3 — Language switching

    func test_languageSelected_persistsToLocaleStore_andUpdatesSelectedLanguageDriver() {
        localeStore.set(.vi)
        let sut = makeSUT()
        let collected = collect(sut.selectedLanguage.asObservable())

        sut.languageSelected.accept(.en)

        XCTAssertEqual(localeStore.language.value, .en)
        XCTAssertEqual(collected().last, .en)
    }

    /// US3 AS5: tapping the *currently selected* row must NOT cause a
    /// re-render. The Driver should only emit its initial replay value
    /// (`.vi`) — no second `.next` for the same value.
    func test_languageSelected_currentLanguage_doesNotReEmit() {
        localeStore.set(.vi)
        let sut = makeSUT()
        let collected = collect(sut.selectedLanguage.asObservable())

        sut.languageSelected.accept(.vi)

        XCTAssertEqual(collected(), [.vi], "Idempotent — only the initial replay")
    }

    func test_oauthCallback_success_navigatesHome() {
        let session = AuthSessionFixture.make()
        repository.exchangeResult = .just(session)
        let sut = makeSUT()

        let navigations = collect(sut.navigateHome.asObservable())

        sut.oauthCallback.accept(URL(string: "aidd-saa-2025://auth-callback?code=abc")!)

        XCTAssertEqual(navigations().count, 1)
        XCTAssertEqual(repository.exchangeCalls.count, 1)
    }
}
