import SwiftUI

/// Organism: status-bar-aligned top navigation with a leading back icon
/// and an optional title slot. Used by Access denied, Not Found, and
/// later by M2 Notifications + M3 Profile.
struct TopNavigation: View {

    var title: LocalizedStringKey? = nil
    var onBack: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 8) {
            if let onBack {
                BackIconButton(action: onBack)
            } else {
                Spacer().frame(width: 44, height: 44)
            }

            Spacer()

            if let title {
                Text(title)
                    .font(.headline)
                    .lineLimit(1)
                    .accessibilityAddTraits(.isHeader)
            }

            Spacer()

            Spacer().frame(width: 44, height: 44)
        }
        .padding(.horizontal, 8)
    }
}
