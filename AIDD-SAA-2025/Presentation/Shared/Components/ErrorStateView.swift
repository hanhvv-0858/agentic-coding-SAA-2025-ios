import SwiftUI

/// Organism: title + divider + subtitle + illustration + primary CTA.
/// Backs both Access denied and Not Found per spec — keeps layout +
/// spacing identical so the two screens read as a coherent family.
struct ErrorStateView: View {

    let title: LocalizedStringKey
    let subtitle: LocalizedStringKey
    let illustrationSystemName: String
    let primaryButtonTitle: LocalizedStringKey
    var primaryButtonHint: LocalizedStringKey? = nil
    let onPrimaryTap: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 12) {
                Text(title)
                    .font(.title2.weight(.semibold))
                    .multilineTextAlignment(.center)
                    .accessibilityAddTraits(.isHeader)

                Divider()
                    .frame(maxWidth: 80)

                Text(subtitle)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 24)

            Image(systemName: illustrationSystemName)
                .resizable()
                .scaledToFit()
                .frame(width: 160, height: 160)
                .foregroundStyle(.tint)
                .accessibilityHidden(true)

            PrimaryButton(
                title: primaryButtonTitle,
                action: onPrimaryTap
            )
            .padding(.horizontal, 24)
            .accessibilityIdentifier("ErrorStateView.primaryButton")
            .modifier(AccessibilityHintIfPresent(hint: primaryButtonHint))
        }
    }
}

private struct AccessibilityHintIfPresent: ViewModifier {
    let hint: LocalizedStringKey?

    func body(content: Content) -> some View {
        if let hint {
            content.accessibilityHint(hint)
        } else {
            content
        }
    }
}
