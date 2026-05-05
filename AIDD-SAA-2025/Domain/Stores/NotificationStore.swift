import Foundation
import RxRelay
import RxSwift

protocol NotificationStoring: AnyObject {
    var unreadCount: BehaviorRelay<Int> { get }
    var hasUnreadObservable: Observable<Bool> { get }
    func set(_ count: Int)
}

/// Hot, app-wide store of the user's unread-notification count. Fed by
/// `ObserveUnreadNotificationsUseCase` (which composes the Realtime
/// subscription + 30 s polling fallback) and consumed by Home's bell-dot
/// and the Notifications inbox.
nonisolated final class NotificationStore: NotificationStoring {
    let unreadCount: BehaviorRelay<Int>

    var hasUnreadObservable: Observable<Bool> {
        unreadCount.asObservable()
            .map { $0 > 0 }
            .distinctUntilChanged()
    }

    init(initial: Int = 0) {
        self.unreadCount = BehaviorRelay(value: max(0, initial))
    }

    /// Floor-clamp at 0 — Supabase shouldn't return negatives but
    /// RLS-denied / unexpected NULLs can coerce to negative values which
    /// must NOT bleed into the UI.
    func set(_ count: Int) {
        unreadCount.accept(max(0, count))
    }
}
