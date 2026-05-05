import Foundation
import RxSwift
import Supabase

protocol NotificationRemoteDataSource: AnyObject {
    /// HEAD count — `select("id", count: .exact, head: true)` so no
    /// row payloads are downloaded just to count.
    func unreadCount(for recipientID: UUID) -> Single<Int>

    /// `update().eq("id", id)` setting `read_at = now()`.
    func markRead(id: UUID) -> Completable

    /// `update().eq("recipient_id", uid).is("read_at", nil)` setting
    /// `read_at = now()` for every still-unread row.
    func markAllRead(for recipientID: UUID) -> Completable
}

nonisolated final class NotificationRemoteDataSourceImpl: NotificationRemoteDataSource {

    private let client: SupabaseClient
    private let scheduler: ImmediateSchedulerType

    init(
        client: SupabaseClient,
        scheduler: ImmediateSchedulerType = ConcurrentDispatchQueueScheduler(qos: .userInitiated)
    ) {
        self.client = client
        self.scheduler = scheduler
    }

    func unreadCount(for recipientID: UUID) -> Single<Int> {
        Single<Int>.create { [weak self] observer in
            guard let self else {
                observer(.failure(NSError(domain: "NotificationDataSource", code: -1)))
                return Disposables.create()
            }
            let task = Task { [weak self] in
                guard let self else { return }
                do {
                    let response = try await self.client
                        .from("notifications")
                        .select("id", head: true, count: .exact)
                        .eq("recipient_id", value: recipientID)
                        .is("read_at", value: nil)
                        .execute()
                    observer(.success(response.count ?? 0))
                } catch {
                    observer(.failure(error))
                }
            }
            return Disposables.create { task.cancel() }
        }
        .subscribe(on: scheduler)
    }

    func markRead(id: UUID) -> Completable {
        Completable.create { [weak self] observer in
            guard let self else {
                observer(.completed)
                return Disposables.create()
            }
            let task = Task { [weak self] in
                guard let self else { return }
                do {
                    try await self.client
                        .from("notifications")
                        .update(["read_at": Date()])
                        .eq("id", value: id)
                        .execute()
                    observer(.completed)
                } catch {
                    observer(.error(error))
                }
            }
            return Disposables.create { task.cancel() }
        }
        .subscribe(on: scheduler)
    }

    func markAllRead(for recipientID: UUID) -> Completable {
        Completable.create { [weak self] observer in
            guard let self else {
                observer(.completed)
                return Disposables.create()
            }
            let task = Task { [weak self] in
                guard let self else { return }
                do {
                    try await self.client
                        .from("notifications")
                        .update(["read_at": Date()])
                        .eq("recipient_id", value: recipientID)
                        .is("read_at", value: nil)
                        .execute()
                    observer(.completed)
                } catch {
                    observer(.error(error))
                }
            }
            return Disposables.create { task.cancel() }
        }
        .subscribe(on: scheduler)
    }
}
