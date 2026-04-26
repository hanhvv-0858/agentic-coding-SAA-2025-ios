import SwiftUI

/// Atom: a back chevron with a HIG-minimum 44×44 hit target.
struct BackIconButton: View {

    let action: () -> Void
    var accessibilityLabelKey: LocalizedStringKey = "Back"

    var body: some View {
        Button(action: action) {
            Image(systemName: "chevron.backward")
                .font(.body.weight(.semibold))
                .foregroundStyle(Color.primary)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabelKey)
        .accessibilityAddTraits(.isButton)
        .accessibilityIdentifier("BackIconButton")
    }
}
