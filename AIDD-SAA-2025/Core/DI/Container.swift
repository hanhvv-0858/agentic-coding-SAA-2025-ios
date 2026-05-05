import Foundation
import RxRelay
import RxSwift
import Supabase
import os

protocol ContainerProtocol: AnyObject {
    var config: AppConfig { get }
    var authStore: AuthStoring { get }
    var localeStore: LocaleStoring { get }
    var router: AppRouting { get }
    var tabRouter: TabRouting { get }
    var notificationStore: NotificationStoring { get }
    var sessionStorage: SessionStoring { get }
    var authRouterBinder: AuthRouterBinder { get }
    var authRepository: AuthRepository { get }
    var analytics: AnalyticsClient { get }
    func makeLoginViewModel() -> LoginViewModel
    func makeAccessDeniedViewModel() -> AccessDeniedViewModel
    func makeNotFoundViewModel() -> NotFoundViewModel
    func makeRestoreSessionUseCase() -> RestoreSessionUseCaseProtocol
    func makeHomeViewModel() -> HomeViewModel
}

nonisolated final class Container: ContainerProtocol {
    let config: AppConfig
    let authStore: AuthStoring
    let localeStore: LocaleStoring
    let router: AppRouting
    let tabRouter: TabRouting
    let notificationStore: NotificationStoring
    let sessionStorage: SessionStoring
    let authRouterBinder: AuthRouterBinder
    let authRepository: AuthRepository
    let analytics: AnalyticsClient
    private let supabase: SupabaseClient

    init(
        config: AppConfig,
        authStore: AuthStoring,
        localeStore: LocaleStoring,
        router: AppRouting,
        tabRouter: TabRouting,
        notificationStore: NotificationStoring,
        sessionStorage: SessionStoring,
        supabase: SupabaseClient,
        authRepository: AuthRepository,
        analytics: AnalyticsClient
    ) {
        self.config = config
        self.authStore = authStore
        self.localeStore = localeStore
        self.router = router
        self.tabRouter = tabRouter
        self.notificationStore = notificationStore
        self.sessionStorage = sessionStorage
        self.supabase = supabase
        self.authRepository = authRepository
        self.analytics = analytics
        self.authRouterBinder = AuthRouterBinder(authStore: authStore, router: router)
    }

    func makeLoginViewModel() -> LoginViewModel {
        let checkEmailDomain = CheckEmailDomainUseCase(
            allowlist: AllowedEmailDomains(domains: config.allowedEmailDomains)
        )
        return LoginViewModelImpl(
            signInUseCase: SignInWithGoogleUseCase(
                repository: authRepository,
                checkEmailDomain: checkEmailDomain
            ),
            exchangeCallbackUseCase: ExchangeOAuthCallbackUseCase(
                repository: authRepository,
                checkEmailDomain: checkEmailDomain
            ),
            setAppLanguageUseCase: SetAppLanguageUseCase(localeStore: localeStore),
            localeStore: localeStore,
            analytics: analytics
        )
    }

    func makeAccessDeniedViewModel() -> AccessDeniedViewModel {
        AccessDeniedViewModelImpl(signOutUseCase: SignOutUseCase(repository: authRepository))
    }

    func makeNotFoundViewModel() -> NotFoundViewModel {
        NotFoundViewModelImpl(authStore: authStore)
    }

    func makeRestoreSessionUseCase() -> RestoreSessionUseCaseProtocol {
        RestoreSessionUseCase(repository: authRepository)
    }

    func makeHomeViewModel() -> HomeViewModel {
        let awardRepository: AwardRepository = AwardRepositoryImpl(
            dataSource: AwardRemoteDataSourceImpl(client: supabase)
        )
        let kudosHighlightRepository: KudosHighlightRepository = KudosHighlightRepositoryImpl()
        let notificationRepository = makeNotificationRepository()
        let fetchHomeFeed = FetchHomeFeedUseCase(
            fetchAwards: FetchAwardsUseCase(repository: awardRepository),
            fetchKudosBanner: FetchKudosHighlightUseCase(repository: kudosHighlightRepository),
            fetchInitialUnreadCount: { [notificationRepository] in
                notificationRepository.unreadCount()
            }
        )
        let observeUnread = ObserveUnreadNotificationsUseCase(
            repository: notificationRepository
        )
        return HomeViewModelImpl(
            eventSchedule: EventSchedule(from: config),
            localeStore: localeStore,
            fetchHomeFeed: fetchHomeFeed,
            notificationStore: notificationStore,
            observeUnreadNotifications: observeUnread,
            tabRouter: tabRouter,
            analytics: analytics
        )
    }

    /// US3: builds the notification repository tree used by Home's
    /// bell + (later) the sibling Notifications inbox. Realtime channel
    /// + polling fallback share the same `currentRecipientID()` closure
    /// that reads from the live `AuthStore`.
    private func makeNotificationRepository() -> NotificationRepository {
        let dataSource = NotificationRemoteDataSourceImpl(client: supabase)
        let realtimeChannel = RealtimeUnreadChannel(client: supabase)
        let polling = PollingFallback()
        let store = authStore
        return NotificationRepositoryImpl(
            dataSource: dataSource,
            realtimeChannel: realtimeChannel,
            pollingFallback: polling,
            currentRecipientID: { [weak store] in
                guard case .signedIn(let session) = store?.state.value else {
                    return nil
                }
                return session.user.id
            }
        )
    }

    static func bootstrap() throws -> Container {
        let config = try AppConfig.load()

        // Fresh-install gate. iOS Keychain entries survive `Delete App`
        // (UserDefaults does not), which on the first reinstall would
        // restore the previous user's session before they ever see
        // Login. Detect "first launch since install" via a UserDefaults
        // flag and wipe BOTH our Keychain entries AND the supabase-swift
        // SDK's internal Keychain (service = "supabase.gotrue.swift").
        let firstLaunch = UserDefaultsFirstLaunchDetector()
        if firstLaunch.consumeFirstLaunch() {
            let bundleService = Bundle.main.bundleIdentifier ?? "com.sun-asterisk.aidd-saa-2025"
            KeychainPurger(services: [
                bundleService,
                "supabase.gotrue.swift"
            ]).purgeAll()
            Log.auth.info("First launch — Keychain purged")
        }

        let authStore = AuthStore()
        let sessionStorage = KeychainSessionStorage()

        // Opt-in to the next-major-release behavior so the SDK emits
        // the locally-stored session verbatim instead of trying to
        // refresh it first. Safe for this app: our `AuthRepositoryImpl`
        // restoreSession() reads our own Keychain and runs the
        // `isExpired` + silent-refresh logic itself, so the SDK's
        // initial-session event drives nothing here. Suppresses the
        // 2026-04 deprecation warning printed at app launch.
        let supabase = SupabaseClient(
            supabaseURL: config.supabaseURL,
            supabaseKey: config.supabaseAnonKey,
            options: SupabaseClientOptions(
                auth: .init(emitLocalSessionAsInitialSession: true)
            )
        )
        let dataSource = SupabaseAuthDataSourceImpl(
            client: supabase,
            redirectURL: config.oauthRedirectURL
        )
        let authRepository = AuthRepositoryImpl(
            dataSource: dataSource,
            sessionStorage: sessionStorage,
            authStore: authStore
        )
        return Container(
            config: config,
            authStore: authStore,
            localeStore: LocaleStore(),
            router: AppRouter(initial: .login),
            tabRouter: TabRouter(),
            notificationStore: NotificationStore(),
            sessionStorage: sessionStorage,
            supabase: supabase,
            authRepository: authRepository,
            analytics: OSLogAnalyticsClient()
        )
    }
}
