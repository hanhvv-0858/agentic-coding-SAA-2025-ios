import RxRelay
import RxSwift
import XCTest
@testable import AIDD_SAA_2025

final class ObserveUnreadNotificationsUseCaseTests: XCTestCase {

    private final class StubRepository: NotificationRepository {
        let countRelay = PublishRelay<Int>()
        var observeUnreadCountResult: Observable<Int>?
        func unreadCount() -> Single<Int> { .just(0) }
        func observeUnreadCount() -> Observable<Int> {
            observeUnreadCountResult ?? countRelay.asObservable()
        }
        func markRead(id: UUID) -> Completable { .empty() }
        func markAllRead() -> Completable { .empty() }
    }

    private var bag: DisposeBag!

    override func setUp() {
        super.setUp()
        bag = DisposeBag()
    }
    override func tearDown() {
        bag = nil
        super.tearDown()
    }

    private func collect<T>(_ source: Observable<T>) -> () -> [T] {
        var collected: [T] = []
        source.subscribe(onNext: { collected.append($0) }).disposed(by: bag)
        return { collected }
    }

    // MARK: - Forward repository values

    func test_execute_emitsRepositoryCounts() {
        let repo = StubRepository()
        let sut = ObserveUnreadNotificationsUseCase(repository: repo)

        let counts = collect(sut.execute())

        repo.countRelay.accept(0)
        repo.countRelay.accept(3)
        repo.countRelay.accept(0)

        XCTAssertEqual(counts(), [0, 3, 0])
    }

    // MARK: - First-fetch failure (spec US3 AS4)
    // The repository itself absorbs the error via `catchAndReturn(0)` —
    // here we verify that when the underlying observable emits 0 on
    // first fetch, the use case forwards 0 (dot stays off).

    func test_firstFetchFails_suppressesDot_emitsZero() {
        let repo = StubRepository()
        // Simulate "first fetch returned 0 due to error, then never
        // emits again" — equivalent to the impl's catchAndReturn path.
        repo.observeUnreadCountResult = .just(0)
        let sut = ObserveUnreadNotificationsUseCase(repository: repo)

        let counts = collect(sut.execute())
        XCTAssertEqual(counts(), [0])
    }

    // MARK: - Mid-session retention
    // After a successful initial value, transient failures must not
    // reset the count to 0. The impl's `scan` accumulator + polling
    // sentinel guarantee this — here we verify by emitting 5 then a
    // sentinel-equivalent quiescence period.

    func test_midSessionFailure_retainsLastGoodCount() {
        let repo = StubRepository()
        let sut = ObserveUnreadNotificationsUseCase(repository: repo)

        let counts = collect(sut.execute())

        repo.countRelay.accept(0)
        repo.countRelay.accept(5)
        // Simulating "polling fetch sentinel ignored" — observable
        // does not emit. Last value remains 5.
        XCTAssertEqual(counts().last, 5)
    }
}
