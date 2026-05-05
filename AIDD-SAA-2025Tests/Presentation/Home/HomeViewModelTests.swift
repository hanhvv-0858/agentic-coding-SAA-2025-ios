import RxCocoa
import RxRelay
import RxSwift
import XCTest
@testable import AIDD_SAA_2025

final class HomeViewModelTests: XCTestCase {

    private let now = Date(timeIntervalSince1970: 1_750_000_000)
    private var disposeBag: DisposeBag!

    override func setUp() {
        super.setUp()
        disposeBag = DisposeBag()
    }

    override func tearDown() {
        disposeBag = nil
        super.tearDown()
    }

    private func makeStore() -> LocaleStore {
        let suiteName = "test.home.\(UUID().uuidString)"
        let storage = UserDefaults(suiteName: suiteName)!
        storage.removePersistentDomain(forName: suiteName)
        return LocaleStore(storage: storage, storageKey: "appLanguage")
    }

    /// Drives the VM with a synchronous tick stream — emits as fast as
    /// the test thread can pump events. Sidesteps the Driver/TestScheduler
    /// async-dispatch trap by keeping all events on the test's main
    /// thread (Driver's `ConcurrentMainScheduler` schedules synchronously
    /// when called from main, which is the case here).
    private final class StubFeedUseCase: FetchHomeFeedUseCaseProtocol {
        var result: Single<HomeFeed> = .just(HomeFeed(awards: [], kudosBanner: nil, unreadNotificationCount: 0))
        func execute() -> Single<HomeFeed> { result }
    }

    private func makeVM(
        target: Date,
        ticks: Observable<Void>,
        nowProvider: (() -> Date)? = nil,
        store: LocaleStore? = nil,
        feed: FetchHomeFeedUseCaseProtocol? = nil,
        notificationStore: NotificationStoring? = nil,
        tabRouter: TabRouting? = nil
    ) -> (HomeViewModelImpl, LocaleStore, NotificationStore) {
        let store = store ?? makeStore()
        let schedule = EventSchedule(targetDate: target, place: "Test", liveStreamURL: nil)
        let provider = nowProvider ?? { self.now }
        let notifs = (notificationStore as? NotificationStore) ?? NotificationStore()
        let vm = HomeViewModelImpl(
            eventSchedule: schedule,
            localeStore: store,
            fetchHomeFeed: feed ?? StubFeedUseCase(),
            notificationStore: notifs,
            tabRouter: tabRouter,
            tickStream: ticks,
            now: provider
        )
        return (vm, store, notifs)
    }

    /// M1 pattern (per `LoginViewModelTests`): subscribe via `asObservable`
    /// and accumulate. Returns a closure that snapshots the collected
    /// list at any time.
    private func collect<T>(_ source: Observable<T>) -> () -> [T] {
        var collected: [T] = []
        source.subscribe(onNext: { collected.append($0) }).disposed(by: disposeBag)
        return { collected }
    }

    // MARK: - Countdown

    func test_viewAppeared_emitsInitialCountdown() {
        let target = now.addingTimeInterval(86_400 + 3_600 + 60) // 1d 1h 1m
        let ticks = PublishRelay<Void>()
        let (vm, _, _) = makeVM(target: target, ticks: ticks.asObservable())

        let countdowns = collect(vm.countdown.asObservable())

        vm.viewAppeared.accept(())
        // initial emit comes from `.startWith(())` — no extra tick needed
        XCTAssertEqual(
            countdowns().last,
            CountdownVM(days: 1, hours: 1, minutes: 1)
        )
    }

    func test_eventInPast_countdownClampsToZero_andHasEnded() {
        let target = now.addingTimeInterval(-3_600) // 1 h ago
        let ticks = PublishRelay<Void>()
        let (vm, _, _) = makeVM(target: target, ticks: ticks.asObservable())

        let countdowns = collect(vm.countdown.asObservable())

        vm.viewAppeared.accept(())

        let last = countdowns().last
        XCTAssertEqual(last, CountdownVM(days: 0, hours: 0, minutes: 0))
        XCTAssertEqual(last?.hasEnded, true)
    }

    func test_subsequentTicks_emitNewCountdown_whenMinuteChanges() {
        let target = now.addingTimeInterval(120) // 2 min ahead
        var nowOffset: TimeInterval = 0
        let nowProvider: () -> Date = { self.now.addingTimeInterval(nowOffset) }
        let ticks = PublishRelay<Void>()
        let (vm, _, _) = makeVM(
            target: target,
            ticks: ticks.asObservable(),
            nowProvider: nowProvider
        )

        let countdowns = collect(vm.countdown.asObservable())

        vm.viewAppeared.accept(())
        // tick after virtual 60 seconds — minutes should drop 2 → 1
        nowOffset = 60
        ticks.accept(())

        let emitted = countdowns()
        XCTAssertTrue(emitted.contains(CountdownVM(days: 0, hours: 0, minutes: 2)))
        XCTAssertTrue(emitted.contains(CountdownVM(days: 0, hours: 0, minutes: 1)))
    }

    // MARK: - showsComingSoon (Q1)

    func test_eventInFuture_showsComingSoon_isTrue() {
        let target = now.addingTimeInterval(3_600)
        let ticks = PublishRelay<Void>()
        let (vm, _, _) = makeVM(target: target, ticks: ticks.asObservable())

        let visibility = collect(vm.showsComingSoon.asObservable())

        vm.viewAppeared.accept(())
        XCTAssertEqual(visibility().last, true)
    }

    func test_eventPassed_showsComingSoon_isFalse() {
        let target = now.addingTimeInterval(-60)
        let ticks = PublishRelay<Void>()
        let (vm, _, _) = makeVM(target: target, ticks: ticks.asObservable())

        let visibility = collect(vm.showsComingSoon.asObservable())

        vm.viewAppeared.accept(())
        XCTAssertEqual(visibility().last, false)
    }

    // MARK: - US2: Awards state machine

    private func sampleAward() -> AwardTeaser {
        AwardTeaser(
            kind: .topTalent,
            titleVI: "Top Talent",
            titleEN: "Top Talent",
            descriptionVI: "vn",
            descriptionEN: "en",
            artworkAssetKey: "award_top_talent",
            displayOrder: 6
        )
    }

    func test_awards_loaded_emitsLoadedState() {
        let target = now.addingTimeInterval(86_400)
        let ticks = PublishRelay<Void>()
        let row = sampleAward()
        let feed = StubFeedUseCase()
        feed.result = .just(HomeFeed(awards: [row], kudosBanner: nil, unreadNotificationCount: 0))
        let (vm, _, _) = makeVM(target: target, ticks: ticks.asObservable(), feed: feed)

        let states = collect(vm.awards.asObservable())
        vm.viewAppeared.accept(())

        XCTAssertEqual(states().last, .loaded([row]))
    }

    func test_awards_emptyArray_emitsEmptyState() {
        let target = now.addingTimeInterval(86_400)
        let ticks = PublishRelay<Void>()
        let feed = StubFeedUseCase()
        feed.result = .just(HomeFeed(awards: [], kudosBanner: nil, unreadNotificationCount: 0))
        let (vm, _, _) = makeVM(target: target, ticks: ticks.asObservable(), feed: feed)

        let states = collect(vm.awards.asObservable())
        vm.viewAppeared.accept(())

        XCTAssertEqual(states().last, .empty)
    }

    // MARK: - US2: Navigation

    func test_awardCardTapped_emitsAwardDetailRoute() {
        let target = now.addingTimeInterval(86_400)
        let ticks = PublishRelay<Void>()
        let (vm, _, _) = makeVM(target: target, ticks: ticks.asObservable())

        let routes = collect(vm.navigate.asObservable())
        vm.awardCardTapped.accept(.topTalent)

        XCTAssertEqual(routes().last, .awardDetail(kind: .topTalent))
    }

    func test_kudosDetailTapped_emitsSunKudosRoute() {
        let target = now.addingTimeInterval(86_400)
        let ticks = PublishRelay<Void>()
        let (vm, _, _) = makeVM(target: target, ticks: ticks.asObservable())

        let routes = collect(vm.navigate.asObservable())
        vm.kudosDetailTapped.accept(())

        XCTAssertEqual(routes().last, .sunKudos)
    }

    // MARK: - US2: Hero CTA scroll anchors

    func test_aboutAwardTapped_emitsAwardsAnchor() {
        let target = now.addingTimeInterval(86_400)
        let ticks = PublishRelay<Void>()
        let (vm, _, _) = makeVM(target: target, ticks: ticks.asObservable())

        let anchors = collect(vm.scrollTo.asObservable())
        vm.aboutAwardTapped.accept(())

        XCTAssertEqual(anchors().last, .awards)
    }

    func test_aboutKudosTapped_emitsKudosAnchor() {
        let target = now.addingTimeInterval(86_400)
        let ticks = PublishRelay<Void>()
        let (vm, _, _) = makeVM(target: target, ticks: ticks.asObservable())

        let anchors = collect(vm.scrollTo.asObservable())
        vm.aboutKudosTapped.accept(())

        XCTAssertEqual(anchors().last, .kudos)
    }

    // MARK: - US3: Bell

    func test_hasUnreadNotifications_reflectsNotificationStore() {
        let target = now.addingTimeInterval(86_400)
        let ticks = PublishRelay<Void>()
        let notifs = NotificationStore()
        let (vm, _, store) = makeVM(
            target: target,
            ticks: ticks.asObservable(),
            notificationStore: notifs
        )

        let states = collect(vm.hasUnreadNotifications.asObservable())

        store.set(0)
        XCTAssertEqual(states().last, false)
        store.set(3)
        XCTAssertEqual(states().last, true)
        store.set(0)
        XCTAssertEqual(states().last, false)
    }

    func test_notificationsTapped_emitsNotificationsRoute() {
        let target = now.addingTimeInterval(86_400)
        let ticks = PublishRelay<Void>()
        let (vm, _, _) = makeVM(target: target, ticks: ticks.asObservable())

        let routes = collect(vm.navigate.asObservable())
        vm.notificationsTapped.accept(())

        XCTAssertEqual(routes().last, .notifications)
    }

    // MARK: - US4: FAB

    func test_fabComposeTapped_emitsWriteKudoRoute() {
        let target = now.addingTimeInterval(86_400)
        let ticks = PublishRelay<Void>()
        let (vm, _, _) = makeVM(target: target, ticks: ticks.asObservable())

        let routes = collect(vm.navigate.asObservable())
        vm.fabComposeTapped.accept(())

        XCTAssertEqual(routes().last, .writeKudo(recipientId: nil))
    }

    func test_fabKudosFeedTapped_emitsSunKudosRoute() {
        let target = now.addingTimeInterval(86_400)
        let ticks = PublishRelay<Void>()
        let (vm, _, _) = makeVM(target: target, ticks: ticks.asObservable())

        let routes = collect(vm.navigate.asObservable())
        vm.fabKudosFeedTapped.accept(())

        XCTAssertEqual(routes().last, .sunKudos)
    }

    func test_fabCompose_inFlightGuard_blocksDoubleTap() {
        let target = now.addingTimeInterval(86_400)
        let ticks = PublishRelay<Void>()
        let (vm, _, _) = makeVM(target: target, ticks: ticks.asObservable())

        let routes = collect(vm.navigate.asObservable())

        vm.fabComposeTapped.accept(())
        vm.fabComposeTapped.accept(())  // second tap blocked by in-flight guard

        let composeRoutes = routes().filter { $0 == .writeKudo(recipientId: nil) }
        XCTAssertEqual(composeRoutes.count, 1)
    }

    func test_fabZones_inFlightGuard_isPerZone_notShared() {
        let target = now.addingTimeInterval(86_400)
        let ticks = PublishRelay<Void>()
        let (vm, _, _) = makeVM(target: target, ticks: ticks.asObservable())

        let routes = collect(vm.navigate.asObservable())

        // Pen zone fires once, then S zone fires — both should land
        // because the in-flight guards are independent.
        vm.fabComposeTapped.accept(())
        vm.fabKudosFeedTapped.accept(())

        XCTAssertTrue(routes().contains(.writeKudo(recipientId: nil)))
        XCTAssertTrue(routes().contains(.sunKudos))
    }

    func test_fabInFlight_clearedOnViewAppeared_reArmsZones() {
        let target = now.addingTimeInterval(86_400)
        let ticks = PublishRelay<Void>()
        let (vm, _, _) = makeVM(target: target, ticks: ticks.asObservable())

        let routes = collect(vm.navigate.asObservable())

        vm.fabComposeTapped.accept(())          // fires
        vm.fabComposeTapped.accept(())          // blocked
        vm.viewAppeared.accept(())              // re-arms
        vm.fabComposeTapped.accept(())          // fires again

        let composeRoutes = routes().filter { $0 == .writeKudo(recipientId: nil) }
        XCTAssertEqual(composeRoutes.count, 2)
    }

    // MARK: - US5: Language switching

    func test_languageTapped_emitsPresentLanguagePicker() {
        let target = now.addingTimeInterval(86_400)
        let ticks = PublishRelay<Void>()
        let (vm, _, _) = makeVM(target: target, ticks: ticks.asObservable())

        let presents = collect(vm.presentLanguagePicker.asObservable())
        vm.languageTapped.accept(())

        XCTAssertEqual(presents().count, 1)
    }

    func test_languageSelected_setsLocaleStore() {
        let target = now.addingTimeInterval(86_400)
        let ticks = PublishRelay<Void>()
        let store = makeStore()
        store.set(.vi)
        let (vm, _, _) = makeVM(target: target, ticks: ticks.asObservable(), store: store)

        vm.languageSelected.accept(.en)
        XCTAssertEqual(store.language.value, .en)
    }

    func test_languageSelected_sameLanguage_isIdempotent_noReEmit() {
        let target = now.addingTimeInterval(86_400)
        let ticks = PublishRelay<Void>()
        let store = makeStore()
        store.set(.vi)
        let (vm, _, _) = makeVM(target: target, ticks: ticks.asObservable(), store: store)

        let langs = collect(store.languageObservable)
        XCTAssertEqual(langs(), [.vi])  // initial seed only

        vm.languageSelected.accept(.vi)  // same — should NOT re-emit
        XCTAssertEqual(langs(), [.vi])
    }

    // MARK: - US6: Pull-to-refresh

    func test_pullToRefresh_triggersFetchHomeFeed() {
        let target = now.addingTimeInterval(86_400)
        let ticks = PublishRelay<Void>()
        let row = sampleAward()
        let feed = StubFeedUseCase()
        var callCount = 0
        feed.result = .deferred {
            callCount += 1
            return .just(HomeFeed(awards: [row], kudosBanner: nil, unreadNotificationCount: 0))
        }
        let (vm, _, _) = makeVM(target: target, ticks: ticks.asObservable(), feed: feed)

        _ = collect(vm.awards.asObservable())  // hot subscribe to drive the chain
        vm.viewAppeared.accept(())
        XCTAssertEqual(callCount, 1)

        vm.pullToRefresh.accept(())
        XCTAssertEqual(callCount, 2)
    }

    func test_isRefreshing_togglesAroundFetch() {
        let target = now.addingTimeInterval(86_400)
        let ticks = PublishRelay<Void>()
        let feed = StubFeedUseCase()
        let (vm, _, _) = makeVM(target: target, ticks: ticks.asObservable(), feed: feed)

        let states = collect(vm.isRefreshing.asObservable())

        vm.viewAppeared.accept(())
        // After viewAppeared completes synchronously: relay flipped
        // true on subscribe, then false on next/dispose. The Driver
        // distinctUntilChanged drops duplicates — last value should
        // be `false` post-fetch.
        XCTAssertEqual(states().last, false)
    }

    // MARK: - US8: Tab bar wiring

    func test_activeReTap_onSAA_emitsScrollToTop() {
        let target = now.addingTimeInterval(86_400)
        let ticks = PublishRelay<Void>()
        let router = TabRouter(initial: .saa)
        let (vm, _, _) = makeVM(target: target, ticks: ticks.asObservable(), tabRouter: router)

        let anchors = collect(vm.scrollTo.asObservable())

        // notifyTap on the same selectedTab → activeTabReTapped fires
        router.notifyTap(.saa)

        XCTAssertEqual(anchors().last, .top)
    }

    func test_activeReTap_onOtherTab_doesNotEmitScrollToTop() {
        let target = now.addingTimeInterval(86_400)
        let ticks = PublishRelay<Void>()
        let router = TabRouter(initial: .kudos)  // user is on kudos tab
        let (vm, _, _) = makeVM(target: target, ticks: ticks.asObservable(), tabRouter: router)

        let anchors = collect(vm.scrollTo.asObservable())

        // re-tap kudos — fires activeTabReTapped(.kudos), but Home VM
        // filters to only `.saa`, so no scrollTo emission.
        router.notifyTap(.kudos)

        XCTAssertFalse(anchors().contains(.top))
    }

    // MARK: - US7: Search

    func test_searchTapped_emitsSearchSunnerRoute() {
        let target = now.addingTimeInterval(86_400)
        let ticks = PublishRelay<Void>()
        let (vm, _, _) = makeVM(target: target, ticks: ticks.asObservable())

        let routes = collect(vm.navigate.asObservable())
        vm.searchTapped.accept(())

        XCTAssertEqual(routes().last, .searchSunner)
    }

    // MARK: - Locale binding

    func test_selectedLanguage_reflectsLocaleStore() {
        let store = makeStore()
        let target = now.addingTimeInterval(86_400)
        let ticks = PublishRelay<Void>()
        let (vm, _, _) = makeVM(target: target, ticks: ticks.asObservable(), store: store)

        let langs = collect(vm.selectedLanguage.asObservable())

        // initial value emits from BehaviorRelay seed
        XCTAssertFalse(langs().isEmpty)
        let initial = store.language.value
        let other: AppLanguage = (initial == .en) ? .vi : .en
        store.set(other)

        XCTAssertEqual(langs().last, other)
    }
}
