import SwiftUI

/// Floating-action-button molecule per design-style.md §9.
/// 89×48 cream pill with 2 distinct tap zones — pen icon (compose
/// Kudo) on the left, Sun*Kudos `S` logo on the right, separated by
/// a `/` glyph. Anchored trailing-bottom on Home above the BottomTabBar.
///
/// Per spec US4 + Q3 default: TWO tap zones, NOT a single button.
/// Each zone has independent debounce + in-flight guard at the VM
/// level — this View just emits the tap action.
struct WriteKudoFAB: View {

    let onCompose: () -> Void
    let onKudosFeed: () -> Void

    var body: some View {
        ZStack {
            // Background pill — visual only; the two child Buttons
            // own the tap surface.
            Capsule()
                .fill(Color("BrandCream"))
                .frame(width: 89, height: 48)
                .shadow(
                    color: .black.opacity(0.25),
                    radius: 4, x: 0, y: 4
                )
                .shadow(
                    color: Color(red: 250/255, green: 226/255, blue: 135/255).opacity(0.6),
                    radius: 6, x: 0, y: 0
                )
                .accessibilityHidden(true)

            HStack(spacing: 0) {
                composeZone
                    .frame(maxWidth: .infinity)
                kudosFeedZone
                    .frame(maxWidth: .infinity)
            }
            .frame(width: 89, height: 48)
        }
        .frame(width: 89, height: 48)
    }

    // MARK: - Zones

    private var composeZone: some View {
        Button(action: onCompose) {
            HStack(spacing: 4) {
                Image("ic_pen")
                    .resizable()
                    .renderingMode(.template)
                    .foregroundStyle(Color("BrandOnCream"))
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                Text(verbatim: "/")
                    .font(.system(size: 24, weight: .regular))
                    .foregroundStyle(Color("BrandOnCream"))
                    .frame(height: 32)
            }
            .frame(minWidth: 44, minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("WriteKudoFAB.compose")
        .accessibilityLabel(Text("home.fab.compose.label"))
        .accessibilityHint(Text("home.fab.compose.hint"))
    }

    private var kudosFeedZone: some View {
        Button(action: onKudosFeed) {
            // Sun*Kudos `S` logo — bundled PNG (replaces earlier
            // SF Symbol substitute, deviation §6 #5 closed).
            Image("ic_Kudos_Logo")
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)
                .frame(minWidth: 44, minHeight: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("WriteKudoFAB.kudosFeed")
        .accessibilityLabel(Text("home.fab.feed.label"))
    }
}
