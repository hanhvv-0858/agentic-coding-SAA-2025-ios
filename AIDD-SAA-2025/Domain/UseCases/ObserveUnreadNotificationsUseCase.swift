import Foundation
import RxRelay
import RxSwift

protocol ObserveUnreadNotificationsUseCaseProtocol {
    /// Hot stream that drives `NotificationStore.unreadCount`. Caller
    /// subscribes once at app boot (or on `viewAppeared` if needed)
    /// and keeps the subscription alive for the session lifetime.
    func execute() -> Observable<Int>
}

/// Per spec US3 + plan §Architecture, this use case is the boundary
/// where:
/// - First-fetch failure → suppress dot (count stays at `0`).
/// - Mid-session failure (after a prior success) → retain last good
///   value (do NOT flicker the dot off).
/// - Defensive `read_at` filter is implemented in the Realtime layer
///   beneath; this use case just consumes the count integer.
nonisolated final class ObserveUnreadNotificationsUseCase: ObserveUnreadNotificationsUseCaseProtocol {

    private let repository: NotificationRepository

    init(repository: NotificationRepository) {
        self.repository = repository
    }

    func execute() -> Observable<Int> {
        // The repository's `observeUnreadCount()` already absorbs
        // first-fetch errors via `catchAndReturn(0)` in
        // `NotificationRepositoryImpl`. Mid-session retention is
        // implemented via the `scan(0)` accumulator: errors after the
        // initial seed are dropped (polling fallback's `-1` sentinel
        // is ignored), so the running count never resets to 0 on
        // transient failure.
        repository.observeUnreadCount()
    }
}
