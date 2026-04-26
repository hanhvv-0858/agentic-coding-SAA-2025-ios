import SwiftUI

/// Molecule: flag + language code + chevron, wrapped in a HIG-minimum
/// 44×44 tap area. Per Figma `[iOS] Login`, the chip sits on a dark
/// brand-keyvisual background — text + chevron are white and the pill
/// background is a soft black overlay.
struct LanguageSwitcherChip: View {

    let language: AppLanguage
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Text(language.flagEmoji)
                    .font(.subheadline)
                Text(language.rawValue.uppercased())
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                Image(systemName: "chevron.down")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.85))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(
                Capsule().fill(Color("ChipBackground"))
            )
            .frame(minWidth: 44, minHeight: 44)
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("LanguageSwitcherChip")
        .accessibilityLabel(
            Text(
                "login.langChip.hint \(language.localizedName)",
                comment: "Voice-over hint announcing the current language"
            )
        )
        .accessibilityAddTraits(.isButton)
    }
}

extension AppLanguage {
    var flagEmoji: String {
        switch self {
        case .vi: return "🇻🇳"
        case .en: return "🇬🇧"
        }
    }

    var localizedName: String {
        switch self {
        case .vi: return String(localized: "lang.vi")
        case .en: return String(localized: "lang.en")
        }
    }
}
