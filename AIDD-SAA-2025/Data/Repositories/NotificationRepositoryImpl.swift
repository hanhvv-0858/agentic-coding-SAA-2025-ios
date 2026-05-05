import Foundation
import RxRelay
import RxSwift

/// Composes the HEAD-count fetch + Realtime CDC events + polling
/// fallback into a single `Observable<Int>` for the rest of the app
/// to consume via `NotificationStore.unreadCount`.
///
/// Per spec edge cases (Phase 2 §plan):
/// - Realtime disconnects mid-session → polling kicks in within 30 s
/// - Realtime fails to subscribe at all → polling starts immediately
/// - Realtime emits `read_at != nil` row → defensive filter drops it
/// - First-fetch HEAD failure → suppress dot (`Int = 0`)
/// - Mid-session HEAD failure → retain last good value
nonisolated final class NotificationRepositoryImpl: NotificationRepository {

    private let dataSource: NotificationRemoteDataSource
    private let realtimeChannel: RealtimeUnreadChannelProtocol
    private let pollingFallback: PollingFallbackProtocol
    private let currentRecipientID: () -> UUID?

    init(
        dataSource: NotificationRemoteDataSource,
        realtimeChannel: RealtimeUnreadChannelProtocol,
        pollingFallback: PollingFallbackProtocol,
        currentRecipientID: @escaping () -> UUID?
    ) {
        self.dataSource = dataSource
        self.realtimeChannel = realtimeChannel
        self.pollingFallback = pollingFallback
        self.currentRecipientID = currentRecipientID
    }

    // MARK: - HEAD count

    func unreadCount() -> Single<Int> {
        guard let uid = currentRecipientID() else {
            return .just(0)
        }
        return dataSource.unreadCount(for: uid)
            .map { max(0, $0) }
    }

    // MARK: - Live stream

    func observeUnreadCount() -> Observable<Int> {
        Observable<Int>.deferred { [weak self] in
            guard let self, let uid = self.currentRecipientID() else {
                // No session — emit 0 and complete; subscribe again on
                // sign-in (caller restarts the stream from `viewAppeared`).
                return .just(0)
            }

            // Initial HEAD fetch — failure clamps to 0 (spec US3 AS4
            // first-fetch suppress).
            let initial = self.dataSource.unreadCount(for: uid)
                .map { max(0, $0) }
                .asObservable()
                .catchAndReturn(0)

            // Realtime CDC events. We map each event to a count delta
            // applied via `scan`. `.channelConnected` / `.channelDisconnected`
            // pass through as 0-delta so the polling fallback can react.
            let realtime = self.realtimeChannel.subscribe(recipientID: uid)
                .catchAndReturn(.channelDisconnected)

            let realtimeDeltas = realtime
                .map { event -> Int in
                    switch event {
                    case .insertedUnread:                return 1
                    case .markedRead, .deletedUnread:    return -1
                    case .channelConnected,
                         .channelDisconnected:           return 0
                    }
                }

            // Polling fallback — re-fetches HEAD count every 30 s. Active
            // when the Realtime channel reports disconnect OR fails to
            // subscribe at all (which manifests as `.catchAndReturn`
            // above emitting `.channelDisconnected` immediately).
            let polledRefetch = self.pollingFallback.tickStream()
                .flatMapLatest { [weak self] _ -> Observable<Int> in
                    guard let self, let uid = self.currentRecipientID() else {
                        return .empty()
                    }
                    return self.dataSource.unreadCount(for: uid)
                        .map { max(0, $0) }
                        .asObservable()
                        .catchAndReturn(-1)  // sentinel for "ignore — keep last value"
                }

            // Compose into a running count.
            // `delta` events from Realtime: combine via scan.
            // `polled` events: replace running count (sentinel -1 → ignore).
            // `initial` event (one-shot): sets the seed.
            return Observable.merge(
                initial.map { CountUpdate.replace($0) },
                realtimeDeltas.map { CountUpdate.delta($0) },
                polledRefetch.map { CountUpdate.replace($0) }
            )
            .scan(0) { acc, update -> Int in
                switch update {
                case .replace(let v) where v < 0:  return acc       // ignore polling sentinel
                case .replace(let v):              return max(0, v)
                case .delta(let d):                return max(0, acc + d)
                }
            }
            .distinctUntilChanged()
        }
    }

    // MARK: - Mark read

    func markRead(id: UUID) -> Completable {
        dataSource.markRead(id: id)
    }

    func markAllRead() -> Completable {
        guard let uid = currentRecipientID() else {
            return .empty()
        }
        return dataSource.markAllRead(for: uid)
    }

    // MARK: - Internal

    private enum CountUpdate {
        case replace(Int)
        case delta(Int)
    }
}
