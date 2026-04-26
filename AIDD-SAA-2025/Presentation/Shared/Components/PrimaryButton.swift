import SwiftUI

/// Atom: brand-primary CTA with optional loading slot. Used by Login,
/// Access denied, Not Found.
struct PrimaryButton: View {

    let title: LocalizedStringKey
    var systemIcon: String? = nil
    var isLoading: Bool = false
    var isEnabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .controlSize(.small)
                        .tint(.white)
                } else if let icon = systemIcon {
                    Image(systemName: icon)
                        .font(.title3)
                }
                Text(title)
                    .font(.headline)
            }
            .frame(maxWidth: .infinity, minHeight: 48)
            .foregroundStyle(.white)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(backgroundColor)
            )
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled || isLoading)
        .accessibilityAddTraits(.isButton)
    }

    private var backgroundColor: Color {
        guard isEnabled else { return Color.accentColor.opacity(0.4) }
        return isLoading ? Color.accentColor.opacity(0.6) : Color.accentColor
    }
}
