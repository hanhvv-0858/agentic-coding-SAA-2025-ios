import SwiftUI

/// Countdown molecule per design-style.md §3.5 (Hero countdown). Renders:
///
/// - The "Coming soon" label (hidden when `showsComingSoon == false`,
///   per Q1 + spec US1 AS4).
/// - Three cells (days / hours / minutes) showing 2-digit values with
///   localised unit labels below.
///
/// Reduced Motion (`UIAccessibility.isReduceMotionEnabled`) is honoured
/// by skipping the digit-transition animation; `accessibilityElement`
/// merges the row so VoiceOver announces it once per change.
struct CountdownTimerView: View {

    let countdown: CountdownVM
    let showsComingSoon: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // "Coming soon" label — hidden when the event has passed.
            // We keep the layout slot reserved with `.opacity(0)` so
            // surrounding spacing doesn't shift when the label flips.
            Text("home.comingSoon")
                .font(.system(size: 14, weight: .light))
                .tracking(0.25)
                .foregroundStyle(.white)
                .opacity(showsComingSoon ? 1 : 0)
                .accessibilityHidden(!showsComingSoon)

            HStack(alignment: .center, spacing: 16) {
                cell(value: countdown.days,    label: "home.countdown.days")
                cell(value: countdown.hours,   label: "home.countdown.hours")
                cell(value: countdown.minutes, label: "home.countdown.minutes")
            }
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.18), value: countdown)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }

    @ViewBuilder
    private func cell(value: Int, label: LocalizedStringKey) -> some View {
        VStack(spacing: 4) {
            Text(twoDigit(value))
                .font(.system(size: 56, weight: .bold))
                .foregroundStyle(.white)
                .monospacedDigit()
            Text(label)
                .font(.system(size: 14, weight: .medium))
                .tracking(1.0)
                .foregroundStyle(.white.opacity(0.85))
        }
        .frame(minWidth: 72, alignment: .center)
    }

    private func twoDigit(_ n: Int) -> String {
        String(format: "%02d", max(0, n))
    }

    private var accessibilityLabel: Text {
        // VoiceOver reads the human-friendly form; the per-second tick
        // is throttled to per-minute by the VM's distinctUntilChanged
        // so this is announced at most once per minute.
        Text(
            "\(countdown.days) ngày, \(countdown.hours) giờ, \(countdown.minutes) phút."
        )
    }
}
