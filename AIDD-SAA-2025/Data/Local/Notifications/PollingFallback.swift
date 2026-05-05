import Foundation
import RxSwift

protocol PollingFallbackProtocol: AnyObject {
    /// Periodic stream of unread counts at the configured interval.
    /// The `NotificationRepositoryImpl` activates this when Realtime
    /// reports `.channelDisconnected` (spec edge case) or fails to
    /// subscribe at all (immediate fallback per edge case).
    func tickStream() -> Observable<Void>
}

/// Emits a `()` event every `interval` seconds (default 30s per spec
/// TR-004). Caller maps each tick to a fresh HEAD-count fetch.
nonisolated final class PollingFallback: PollingFallbackProtocol {

    private let interval: RxTimeInterval
    private let scheduler: SchedulerType

    init(
        interval: RxTimeInterval = .seconds(30),
        scheduler: SchedulerType = MainScheduler.instance
    ) {
        self.interval = interval
        self.scheduler = scheduler
    }

    func tickStream() -> Observable<Void> {
        Observable<Int>
            .interval(interval, scheduler: scheduler)
            .map { _ in () }
    }
}
