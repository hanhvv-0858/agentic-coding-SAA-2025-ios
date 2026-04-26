import SwiftUI

/// Anchored dropdown that pairs with `LanguageSwitcherChip`. Per
/// `design-style.md` §4 (Figma `[iOS] Language dropdown`):
/// - card 122 × 92 pt (110 × 80 inner + 6 pt padding all sides)
/// - bg `DropdownBackground` (`#00070C`)
/// - 1 pt `DropdownBorder` (`#998C5F`) stroke
/// - 8 pt corner radius
/// - selected row tinted `BrandCream` at 20 % (`#FFEA9E33`)
/// - rows 110 × 40 pt, 16 pt padding, 2 pt corner radius
/// - 14 pt / 500 white text, +0.10 letter-spacing
struct LanguagePickerDropdown: View {

    let currentLanguage: AppLanguage
    let onSelect: (AppLanguage) -> Void

    var body: some View {
        VStack(spacing: 0) {
            row(for: .vi)
            row(for: .en)
        }
        .padding(6)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color("DropdownBackground"))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(Color("DropdownBorder"), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.35), radius: 16, y: 6)
        .accessibilityIdentifier("LanguagePickerDropdown")
    }

    private func row(for language: AppLanguage) -> some View {
        let isSelected = (language == currentLanguage)
        return Button(action: { onSelect(language) }) {
            HStack(spacing: 4) {
                Text(language.flagEmoji)
                    .font(.system(size: 14))
                    .frame(width: 24, height: 24)

                Text(language.rawValue.uppercased())
                    .font(.system(size: 14, weight: .medium))
                    .tracking(0.10)
                    .foregroundStyle(.white)

                Spacer(minLength: 0)
            }
            .padding(16)
            .frame(width: 110, height: 40)
            .background(
                RoundedRectangle(cornerRadius: 2)
                    .fill(isSelected ? Color("BrandCream").opacity(0.20) : Color.clear)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
        .accessibilityIdentifier("LanguagePickerDropdown.row.\(language.rawValue)")
    }
}
