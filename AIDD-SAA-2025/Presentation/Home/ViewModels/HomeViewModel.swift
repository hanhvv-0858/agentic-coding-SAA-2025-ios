import Foundation
import RxCocoa
import RxRelay
import RxSwift

/// Same-screen scroll anchors for the Home `ScrollView`.
enum HomeAnchor: Equatable {
    case top
    case awards
    case kudos
}

/// Reactive contract for the Home screen. Per spec [State Management]
/// + plan §Architecture, US1 + US2 surface is exposed; subsequent US
/// phases extend the protocol with their inputs/outputs (Bell, FAB,
/// Pull-to-refresh, etc.).
protocol HomeViewModel: AnyObject {
    // Inputs
    var viewAppeared: PublishRelay<Void> { get }
    var awardCardTapped: PublishRelay<AwardKind> { get }
    var aboutAwardTapped: PublishRelay<Void> { get }
    var aboutKudosTapped: PublishRelay<Void> { get }
    var kudosDetailTapped: PublishRelay<Void> { get }
    var notificationsTapped: PublishRelay<Void> { get }
    var fabComposeTapped: PublishRelay<Void> { get }
    var fabKudosFeedTapped: PublishRelay<Void> { get }
    var languageTapped: PublishRelay<Void> { get }
    var languageSelected: PublishRelay<AppLanguage> { get }
    var pullToRefresh: PublishRelay<Void> { get }
    var searchTapped: PublishRelay<Void> { get }

    // Outputs
    var countdown: Driver<CountdownVM> { get }
    var showsComingSoon: Driver<Bool> { get }
    var selectedLanguage: Driver<AppLanguage> { get }
    var awards: Driver<AwardsTeaserState> { get }
    var kudosBanner: Driver<KudosBannerState> { get }
    var hasUnreadNotifications: Driver<Bool> { get }
    var isRefreshing: Driver<Bool> { get }
    var navigate: Signal<AppRoute> { get }
    var scrollTo: Signal<HomeAnchor> { get }
    var presentLanguagePicker: Signal<Void> { get }
}

/// Production implementation. Constitution III: Driver/Signal outputs
/// only; `subscribe(on:)` / `observe(on:)` set explicitly at SDK
/// boundaries.
nonisolated final class HomeViewModelImpl: HomeViewModel {

    // Inputs
    let viewAppeared = PublishRelay<Void>()
    let awardCardTapped = PublishRelay<AwardKind>()
    let aboutAwardTapped = PublishRelay<Void>()
    let aboutKudosTapped = PublishRelay<Void>()
    let kudosDetailTapped = PublishRelay<Void>()
    let notificationsTapped = PublishRelay<Void>()
    let fabComposeTapped = PublishRelay<Void>()
    let fabKudosFeedTapped = PublishRelay<Void>()
    let languageTapped = PublishRelay<Void>()
    let languageSelected = PublishRelay<AppLanguage>()
    let pullToRefresh = PublishRelay<Void>()
    let searchTapped = PublishRelay<Void>()

    // Outputs
    let countdown: Driver<CountdownVM>
    let showsComingSoon: Driver<Bool>
    let selectedLanguage: Driver<AppLanguage>
    let awards: Driver<AwardsTeaserState>
    let kudosBanner: Driver<KudosBannerState>
    let hasUnreadNotifications: Driver<Bool>
    let isRefreshing: Driver<Bool>
    let navigate: Signal<AppRoute>
    let scrollTo: Signal<HomeAnchor>
    let presentLanguagePicker: Signal<Void>

    private let disposeBag = DisposeBag()

    init(
        eventSchedule: EventSchedule,
        localeStore: LocaleStoring,
        fetchHomeFeed: FetchHomeFeedUseCaseProtocol,
        notificationStore: NotificationStoring,
        observeUnreadNotifications: ObserveUnreadNotificationsUseCaseProtocol? = nil,
        tabRouter: TabRouting? = nil,
        analytics: AnalyticsClient? = nil,
        tickStream: Observable<Void>? = nil,
        now: @escaping () -> Date = { Date() }
    ) {
        // ───── Countdown (US1) ─────
        // `tickStream` is injectable for tests — production defaults to
        // a real `Observable<Int>.interval(.seconds(1))`. Tests pass a
        // `PublishRelay<Void>` and emit ticks synchronously, sidestepping
        // the `Driver`-on-`TestScheduler` async-dispatch trap.
        let target = eventSchedule.targetDate
        let resolvedTicks: Observable<Void> = tickStream ?? Observable<Int>
            .interval(.seconds(1), scheduler: MainScheduler.instance)
            .map { _ in () }
        let countdownStream = viewAppeared
            .flatMapLatest { _ in
                resolvedTicks.startWith(())
            }
            .map { _ in CountdownVM.from(target: target, now: now()) }
            .distinctUntilChanged()
            .share(replay: 1, scope: .whileConnected)

        self.countdown = countdownStream
            .asDriver(onErrorJustReturn: CountdownVM(days: 0, hours: 0, minutes: 0))

        // Q1 resolution: hide "Coming soon" when event has passed.
        self.showsComingSoon = countdownStream
            .map { !$0.hasEnded }
            .distinctUntilChanged()
            .asDriver(onErrorJustReturn: false)

        self.selectedLanguage = localeStore.languageObservable
            .asDriver(onErrorJustReturn: AppLanguage.default)

        // ───── Analytics events (TR-007 — no PII) ─────
        // Wired only if `analytics` is injected (tests can opt out).
        if let analytics {
            viewAppeared
                .take(1)
                .subscribe(onNext: { _ in analytics.track(.homeViewed) })
                .disposed(by: disposeBag)
            awardCardTapped
                .subscribe(onNext: { kind in
                    analytics.track(.homeAwardCardTapped(kind: kind.rawValue))
                })
                .disposed(by: disposeBag)
            kudosDetailTapped
                .subscribe(onNext: { _ in analytics.track(.homeKudosDetailTapped) })
                .disposed(by: disposeBag)
            notificationsTapped
                .withLatestFrom(notificationStore.unreadCount.asObservable())
                .subscribe(onNext: { count in
                    let bucket: String
                    switch count {
                    case 0:    bucket = "0"
                    case 1...5: bucket = "1-5"
                    default:    bucket = "6+"
                    }
                    analytics.track(.homeBellTapped(unreadBucket: bucket))
                })
                .disposed(by: disposeBag)
            fabComposeTapped
                .subscribe(onNext: { _ in analytics.track(.homeFabComposeTapped) })
                .disposed(by: disposeBag)
            fabKudosFeedTapped
                .subscribe(onNext: { _ in analytics.track(.homeFabKudosFeedTapped) })
                .disposed(by: disposeBag)
            searchTapped
                .subscribe(onNext: { _ in analytics.track(.homeSearchTapped) })
                .disposed(by: disposeBag)
            languageSelected
                .subscribe(onNext: { lang in
                    analytics.track(.homeLanguageChanged(locale: lang.rawValue))
                })
                .disposed(by: disposeBag)
            pullToRefresh
                .subscribe(onNext: { _ in analytics.track(.homePullToRefresh) })
                .disposed(by: disposeBag)
            aboutAwardTapped
                .subscribe(onNext: { _ in analytics.track(.homeAboutAwardTapped) })
                .disposed(by: disposeBag)
            aboutKudosTapped
                .subscribe(onNext: { _ in analytics.track(.homeAboutKudosTapped) })
                .disposed(by: disposeBag)
        }

        // ───── Home feed: awards + kudos banner (US2 + US6) ─────
        // `viewAppeared` triggers the initial fetch; `pullToRefresh`
        // re-fires the same use case with `flatMapLatest` semantics
        // (a refresh during initial-load cancels the initial fetch
        // per spec edge case "Pull-to-refresh during initial load").
        let isRefreshingRelay = BehaviorRelay<Bool>(value: false)

        let feedTrigger: Observable<Void> = Observable
            .merge(
                viewAppeared.asObservable(),
                pullToRefresh.asObservable()
            )

        let feedStream: Observable<HomeFeed?> = feedTrigger
            .flatMapLatest { _ -> Observable<HomeFeed?> in
                fetchHomeFeed.execute()
                    .asObservable()
                    .do(
                        onNext: { _ in isRefreshingRelay.accept(false) },
                        onError: { _ in isRefreshingRelay.accept(false) },
                        onSubscribe: { isRefreshingRelay.accept(true) },
                        onDispose: { isRefreshingRelay.accept(false) }
                    )
                    .map { Optional($0) }
                    .catchAndReturn(nil)  // cross-cutting failure → "no feed yet"
            }
            .startWith(nil)
            .share(replay: 1, scope: .whileConnected)

        self.isRefreshing = isRefreshingRelay
            .asDriver()
            .distinctUntilChanged()

        self.awards = feedStream
            .map { feed -> AwardsTeaserState in
                guard let feed else { return .loading }
                if feed.awards.isEmpty { return .empty }
                return .loaded(feed.awards)
            }
            .distinctUntilChanged()
            .asDriver(onErrorJustReturn: .error)

        self.kudosBanner = feedStream
            .map { feed -> KudosBannerState in
                guard let feed else { return .loading }
                if let banner = feed.kudosBanner { return .loaded(banner) }
                return .empty
            }
            .distinctUntilChanged()
            .asDriver(onErrorJustReturn: .empty)

        // ───── Bell unread state (US3) ─────
        self.hasUnreadNotifications = notificationStore.hasUnreadObservable
            .asDriver(onErrorJustReturn: false)

        // Hot-subscribe the unread-count observation pipeline tied to
        // Home's `viewAppeared` lifecycle: subscribe on first appear,
        // re-subscribe on each subsequent appear (handles foreground
        // transitions). The Realtime + polling-fallback machinery lives
        // beneath the use case.
        if let observeUseCase = observeUnreadNotifications {
            viewAppeared
                .flatMapLatest { _ in
                    observeUseCase.execute()
                        .catchAndReturn(0)
                }
                .observe(on: MainScheduler.instance)
                .subscribe(onNext: { [weak notificationStore] count in
                    notificationStore?.set(count)
                })
                .disposed(by: disposeBag)
        }

        // ───── FAB tap zones (US4) ─────
        // Per spec US4 AS3: 300ms debounce + per-zone in-flight guard.
        // Per AS5: in-flight relays cleared on `viewAppeared` so the
        // "tap → navigate away → return to Home" cycle re-arms both
        // zones.
        let composeInFlight = BehaviorRelay<Bool>(value: false)
        let kudosFeedInFlight = BehaviorRelay<Bool>(value: false)

        viewAppeared
            .subscribe(onNext: { _ in
                composeInFlight.accept(false)
                kudosFeedInFlight.accept(false)
            })
            .disposed(by: disposeBag)

        // Per-zone in-flight guard handles BOTH the rapid-double-tap
        // case (synchronous re-emit blocked by `inFlight == true`) and
        // the navigate-and-return cycle (cleared by `viewAppeared`
        // above). No additional throttle needed — adding one would
        // race against `viewAppeared`-driven re-arms.
        let composeNav = fabComposeTapped
            .withLatestFrom(composeInFlight) { _, inFlight in inFlight }
            .filter { !$0 }
            .do(onNext: { _ in composeInFlight.accept(true) })
            .map { _ -> AppRoute in .writeKudo(recipientId: nil) }

        let kudosFeedNav = fabKudosFeedTapped
            .withLatestFrom(kudosFeedInFlight) { _, inFlight in inFlight }
            .filter { !$0 }
            .do(onNext: { _ in kudosFeedInFlight.accept(true) })
            .map { _ -> AppRoute in .sunKudos }

        // ───── Navigation (US2 + US3 + US4) ─────
        let cardNav = awardCardTapped
            .map { kind -> AppRoute in .awardDetail(kind: kind) }
        let kudosNav = kudosDetailTapped
            .map { _ -> AppRoute in .sunKudos }
        let notificationsNav = notificationsTapped
            .map { _ -> AppRoute in .notifications }
        let searchNav = searchTapped
            .map { _ -> AppRoute in .searchSunner }
        self.navigate = Observable
            .merge(cardNav, kudosNav, notificationsNav, composeNav, kudosFeedNav, searchNav)
            .asSignal(onErrorSignalWith: .empty())

        // ───── Scroll anchors (US2 + US8) ─────
        let aboutAwardScroll = aboutAwardTapped.map { _ -> HomeAnchor in .awards }
        let aboutKudosScroll = aboutKudosTapped.map { _ -> HomeAnchor in .kudos }
        // US8 AS4: tap the active SAA tab → Home scrolls to top.
        let activeReTapScroll: Observable<HomeAnchor> = (tabRouter?.activeTabReTapped ?? .empty())
            .filter { $0 == .saa }
            .map { _ -> HomeAnchor in .top }
        self.scrollTo = Observable
            .merge(aboutAwardScroll, aboutKudosScroll, activeReTapScroll)
            .asSignal(onErrorSignalWith: .empty())

        // ───── Language picker (US5) ─────
        // Chip tap → present dropdown overlay; selection mutates
        // `LocaleStore` (idempotent — same language is dropped at the
        // store level per AS3, so no re-emit / re-render churn).
        self.presentLanguagePicker = languageTapped
            .asSignal(onErrorSignalWith: .empty())

        languageSelected
            .subscribe(onNext: { language in
                localeStore.set(language)
            })
            .disposed(by: disposeBag)
    }
}
