import Foundation
import RxRelay
import RxSwift
import Realtime
import Supabase
import os

/// Events emitted by the Realtime channel for `public.notifications`.
enum RealtimeUnreadEvent: Equatable {
    /// New row inserted — increment unread by 1 IF `readAt == nil`.
    case insertedUnread
    /// Existing row's `read_at` flipped from `nil` to non-nil —
    /// decrement unread by 1.
    case markedRead
    /// Existing row deleted — decrement if it was unread.
    case deletedUnread

    /// Connection-state events that the polling-fallback uses.
    case channelConnected
    case channelDisconnected
}

protocol RealtimeUnreadChannelProtocol: AnyObject {
    /// Hot stream of CDC events filtered to `recipient_id = uid` plus
    /// connection-state markers. Caller composes with HEAD count +
    /// PollingFallback to derive the live unread count.
    func subscribe(recipientID: UUID) -> Observable<RealtimeUnreadEvent>
}

/// Live data source backed by `supabase-swift` Realtime. Bridges the
/// SDK's `AsyncStream<AnyAction>` into RxSwift `Observable` and emits
/// connection-state events so `NotificationRepositoryImpl` can switch
/// to the polling fallback on disconnect (per spec edge cases:
/// "Realtime channel disconnects" + "Realtime channel fails to
/// subscribe at all").
nonisolated final class RealtimeUnreadChannel: RealtimeUnreadChannelProtocol {

    private let client: SupabaseClient

    init(client: SupabaseClient) {
        self.client = client
    }

    func subscribe(recipientID: UUID) -> Observable<RealtimeUnreadEvent> {
        Observable<RealtimeUnreadEvent>.create { [weak self] observer in
            guard let self else {
                observer.onCompleted()
                return Disposables.create()
            }
            let channel = self.client.channel("notifications:\(recipientID.uuidString)")
            let inserts = channel.postgresChange(
                InsertAction.self,
                schema: "public",
                table: "notifications",
                filter: "recipient_id=eq.\(recipientID.uuidString)"
            )
            let updates = channel.postgresChange(
                UpdateAction.self,
                schema: "public",
                table: "notifications",
                filter: "recipient_id=eq.\(recipientID.uuidString)"
            )
            let deletes = channel.postgresChange(
                DeleteAction.self,
                schema: "public",
                table: "notifications",
                filter: "recipient_id=eq.\(recipientID.uuidString)"
            )

            let task = Task { [weak self] in
                guard let self else { return }
                do {
                    await channel.subscribe()
                    observer.onNext(.channelConnected)
                    Log.notifications.info("Realtime channel subscribed for recipient")

                    await withTaskGroup(of: Void.self) { group in
                        group.addTask {
                            for await action in inserts {
                                if Self.isUnread(action.record) {
                                    observer.onNext(.insertedUnread)
                                }
                            }
                        }
                        group.addTask {
                            for await action in updates {
                                let wasUnread = Self.isUnread(action.oldRecord)
                                let nowUnread = Self.isUnread(action.record)
                                if wasUnread && !nowUnread {
                                    observer.onNext(.markedRead)
                                }
                            }
                        }
                        group.addTask {
                            for await action in deletes {
                                if Self.isUnread(action.oldRecord) {
                                    observer.onNext(.deletedUnread)
                                }
                            }
                        }
                    }
                }
            }

            return Disposables.create {
                task.cancel()
                Task {
                    await channel.unsubscribe()
                    observer.onNext(.channelDisconnected)
                    Log.notifications.info("Realtime channel unsubscribed")
                }
            }
        }
    }

    /// Inspects a Realtime row payload's `read_at` column. Returns
    /// `true` when the row is currently unread (`read_at == nil` or
    /// missing). Defensive: bad payloads default to "treat as
    /// already-read" so we never increment on garbage events
    /// (deviation §6 #11 NEW — TBD if it surfaces).
    private static func isUnread(_ record: [String: AnyJSON]) -> Bool {
        guard let readAt = record["read_at"] else { return false }
        switch readAt {
        case .null: return true
        default:    return false
        }
    }
}
