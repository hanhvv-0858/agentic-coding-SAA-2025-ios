import Foundation
import RxSwift

/// Domain surface for the `public.notifications` table. M2 PR-M2.2
/// part 2 (Phase 5) wires only the count + Realtime subscription +
/// mark-read writes; the full inbox list/feed lives in the sibling
/// Notifications spec.
protocol NotificationRepository: AnyObject {
    /// One-shot HEAD count (`head: true, count: "exact"`) — uses no
    /// row payload, only the `Content-Range` header (per spec
    /// Constitution V — don't leak content).
    func unreadCount() -> Single<Int>

    /// Hot stream of unread counts. Combines:
    /// - Initial HEAD fetch on subscribe
    /// - Supabase Realtime CDC events on `public.notifications`
    /// - 30-second polling fallback when Realtime disconnects
    /// Defensive client-side filter drops Realtime rows with
    /// `read_at != nil` before they reach the relay.
    func observeUnreadCount() -> Observable<Int>

    /// Sets `read_at = now()` on a single row. RLS guards `recipient_id`.
    func markRead(id: UUID) -> Completable

    /// Bulk mark all current user's unread rows as read.
    func markAllRead() -> Completable
}
