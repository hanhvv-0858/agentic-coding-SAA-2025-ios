import Foundation

/// Pure value type representing the days / hours / minutes remaining
/// until the SAA event. Computed from `target − now`, clamped to
/// non-negative values per spec US1 AS4 + Q1 resolution: when the
/// event has passed the row is `0 / 0 / 0` and the "Coming soon"
/// label is hidden.
struct CountdownVM: Equatable {
    let days: Int
    let hours: Int
    let minutes: Int

    /// `true` when `target ≤ now`. The View hides the "Coming soon"
    /// label and renders the static `00 / 00 / 00` row in this state.
    var hasEnded: Bool { days == 0 && hours == 0 && minutes == 0 }

    /// Pure factory — single source of truth for the countdown math.
    /// Negative intervals clamp to zero; sub-minute intervals round
    /// down to zero minutes (the row never shows seconds).
    static func from(target: Date, now: Date) -> CountdownVM {
        let interval = max(0, target.timeIntervalSince(now))
        let totalMinutes = Int(interval / 60)        // floor seconds → minutes
        let days = totalMinutes / 1_440              // 60 * 24
        let hoursRem = totalMinutes - days * 1_440
        let hours = hoursRem / 60
        let minutes = hoursRem - hours * 60
        return CountdownVM(days: days, hours: hours, minutes: minutes)
    }
}
