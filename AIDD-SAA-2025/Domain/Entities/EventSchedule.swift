import Foundation

/// Static event metadata for the SAA 2025 hero on Home. Loaded once
/// from `AppConfig` (xcconfig values bundled at build time per spec
/// API requirements — "no backend call for the countdown source").
struct EventSchedule: Equatable {
    let targetDate: Date
    let place: String
    let liveStreamURL: URL?

    init(targetDate: Date, place: String, liveStreamURL: URL?) {
        self.targetDate = targetDate
        self.place = place
        self.liveStreamURL = liveStreamURL
    }

    init(from config: AppConfig) {
        self.init(
            targetDate: config.eventTargetDate,
            place: config.eventPlace,
            liveStreamURL: config.liveStreamURL
        )
    }
}
