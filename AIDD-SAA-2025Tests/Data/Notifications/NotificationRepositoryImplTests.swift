import RxBlocking
import RxRelay
import RxSwift
import XCTest
@testable import AIDD_SAA_2025

final class NotificationRepositoryImplTests: XCTestCase {

    private final class StubDataSource: NotificationRemoteDataSource {
        var unreadCountResult: Single<Int> = .just(0)
        var unreadCountCalls = 0
        var markReadCalls = 0
        var markAllReadCalls = 0

        func unreadCount(for recipientID: UUID) -> Single<Int> {
            unreadCountCalls += 1
            return unreadCountResult
        }
        func markRead(id: UUID) -> Completable {
            markReadCalls += 1
            return .empty()
        }
        func markAllRead(for recipientID: UUID) -> Completable {
            markAllReadCalls += 1
            return .empty()
        }
    }

    private final class StubRealtimeChannel: RealtimeUnreadChannelProtocol {
        let events = PublishRelay<RealtimeUnreadEvent>()
        var subscribeCalls = 0
        func subscribe(recipientID: UUID) -> Observable<RealtimeUnreadEvent> {
            subscribeCalls += 1
            return events.asObservable()
        }
    }

    private final class StubPolling: PollingFallbackProtocol {
        let ticks = PublishRelay<Void>()
        func tickStream() -> Observable<Void> { ticks.asObservable() }
    }

    private let uid = UUID()
    private var bag: DisposeBag!

    override func setUp() {
        super.setUp()
        bag = DisposeBag()
    }
    override func tearDown() {
        bag = nil
        super.tearDown()
    }

    private func makeSUT(
        ds: StubDataSource = StubDataSource(),
        rt: StubRealtimeChannel = StubRealtimeChannel(),
        poll: StubPolling = StubPolling(),
        recipient: UUID? = nil
    ) -> (NotificationRepositoryImpl, StubDataSource, StubRealtimeChannel, StubPolling) {
        let r = recipient ?? uid
        let sut = NotificationRepositoryImpl(
            dataSource: ds,
            realtimeChannel: rt,
            pollingFallback: poll,
            currentRecipientID: { r }
        )
        return (sut, ds, rt, poll)
    }

    private func collect<T>(_ source: Observable<T>) -> () -> [T] {
        var collected: [T] = []
        source.subscribe(onNext: { collected.append($0) }).disposed(by: bag)
        return { collected }
    }

    // MARK: - HEAD count

    func test_unreadCount_floorClampsNegative() throws {
        let ds = StubDataSource()
        ds.unreadCountResult = .just(-5)
        let (sut, _, _, _) = makeSUT(ds: ds)

        let value = try sut.unreadCount().toBlocking().single()
        XCTAssertEqual(value, 0)
    }

    func test_unreadCount_returnsZero_whenNoSession() throws {
        let sut = NotificationRepositoryImpl(
            dataSource: StubDataSource(),
            realtimeChannel: StubRealtimeChannel(),
            pollingFallback: StubPolling(),
            currentRecipientID: { nil }
        )
        let value = try sut.unreadCount().toBlocking().single()
        XCTAssertEqual(value, 0)
    }

    // MARK: - Live stream — Realtime increments

    func test_observeUnreadCount_initialFetch_seedsCount() {
        let ds = StubDataSource()
        ds.unreadCountResult = .just(2)
        let (sut, _, _, _) = makeSUT(ds: ds)

        let counts = collect(sut.observeUnreadCount())
        XCTAssertEqual(counts().last, 2)
    }

    func test_observeUnreadCount_realtimeInsert_incrementsCount() {
        let ds = StubDataSource()
        ds.unreadCountResult = .just(1)
        let rt = StubRealtimeChannel()
        let (sut, _, _, _) = makeSUT(ds: ds, rt: rt)

        let counts = collect(sut.observeUnreadCount())
        rt.events.accept(.insertedUnread)

        XCTAssertEqual(counts().last, 2)
    }

    func test_observeUnreadCount_realtimeMarkedRead_decrementsCount() {
        let ds = StubDataSource()
        ds.unreadCountResult = .just(3)
        let rt = StubRealtimeChannel()
        let (sut, _, _, _) = makeSUT(ds: ds, rt: rt)

        let counts = collect(sut.observeUnreadCount())
        rt.events.accept(.markedRead)

        XCTAssertEqual(counts().last, 2)
    }

    func test_observeUnreadCount_decrementsClampToZero() {
        let ds = StubDataSource()
        ds.unreadCountResult = .just(0)
        let rt = StubRealtimeChannel()
        let (sut, _, _, _) = makeSUT(ds: ds, rt: rt)

        let counts = collect(sut.observeUnreadCount())
        rt.events.accept(.markedRead)
        rt.events.accept(.markedRead)

        XCTAssertEqual(counts().last, 0)
    }

    // MARK: - First-fetch failure (US3 AS4)

    func test_observeUnreadCount_firstFetchFails_emitsZero_dotSuppressed() {
        struct BoomError: Error {}
        let ds = StubDataSource()
        ds.unreadCountResult = .error(BoomError())
        let (sut, _, _, _) = makeSUT(ds: ds)

        let counts = collect(sut.observeUnreadCount())
        XCTAssertEqual(counts().first, 0)
    }

    // MARK: - Mid-session: polling fetch sentinel ignored

    func test_observeUnreadCount_pollingFetchFailure_keepsLastGood() {
        let ds = StubDataSource()
        ds.unreadCountResult = .just(4)
        let rt = StubRealtimeChannel()
        let poll = StubPolling()
        let (sut, _, _, _) = makeSUT(ds: ds, rt: rt, poll: poll)

        let counts = collect(sut.observeUnreadCount())
        XCTAssertEqual(counts().last, 4)

        // Now polling tick fires after a transient HEAD fetch failure
        // (impl returns -1 sentinel which the scan accumulator drops).
        ds.unreadCountResult = .error(NSError(domain: "transient", code: 503))
        poll.ticks.accept(())

        // Last good value retained.
        XCTAssertEqual(counts().last, 4)
    }

    // MARK: - Polling refresh on success

    func test_observeUnreadCount_pollingFetchSuccess_replacesCount() {
        let ds = StubDataSource()
        ds.unreadCountResult = .just(2)
        let rt = StubRealtimeChannel()
        let poll = StubPolling()
        let (sut, _, _, _) = makeSUT(ds: ds, rt: rt, poll: poll)

        let counts = collect(sut.observeUnreadCount())
        XCTAssertEqual(counts().last, 2)

        ds.unreadCountResult = .just(7)
        poll.ticks.accept(())

        XCTAssertEqual(counts().last, 7)
    }

    // MARK: - Realtime channel-state events are deltas of zero

    func test_observeUnreadCount_channelDisconnected_doesNotChangeCount() {
        let ds = StubDataSource()
        ds.unreadCountResult = .just(3)
        let rt = StubRealtimeChannel()
        let (sut, _, _, _) = makeSUT(ds: ds, rt: rt)

        let counts = collect(sut.observeUnreadCount())
        rt.events.accept(.channelDisconnected)
        rt.events.accept(.channelConnected)

        XCTAssertEqual(counts().last, 3)
    }
}
