import SwiftUI

/// Home header organism per design-style.md §3.2. Logo (48×44) anchored
/// left at y=8 (relative to safe-area top), and a right-aligned cluster
/// of language chip + search icon + bell icon at y=20 (12 pt offset
/// below the logo top — Δ matches Figma).
///
/// US1 PR-M2.2 part 1 wires:
/// - Language chip (re-uses M1 `LanguageSwitcherChip`).
/// - Search button → emits `onSearch` (caller wires to navigate).
/// - Bell button → emits `onNotifications` (caller wires to navigate).
/// - `UnreadDotBadge` overlay on the bell, driven by `hasUnreadNotifications`.
///
/// The full layout follows Figma's "logo at y=52, cluster at y=64"
/// but the parent container (`HomeView`) applies the y=8 / y=20 offsets
/// from the safe-area top — see `LoginView.swift` for the same pattern.
struct HomeHeader: View {

    let language: AppLanguage
    let hasUnreadNotifications: Bool
    let onLanguage: () -> Void
    let onSearch: () -> Void
    let onNotifications: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            Image("BrandLogoSmall")
                .resizable()
                .scaledToFit()
                .frame(width: 48, height: 44)
                .accessibilityHidden(true)

            Spacer(minLength: 0)

            // Right-aligned cluster — gap 10 pt per design-style §3.2.
            HStack(alignment: .center, spacing: 10) {
                LanguageSwitcherChip(language: language, action: onLanguage)

                Button(action: onSearch) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 22, weight: .regular))
                        .foregroundStyle(.white)
                        .frame(width: 24, height: 24)
                        .frame(minWidth: 44, minHeight: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("HomeHeader.searchButton")
                .accessibilityLabel(Text("home.header.searchAccessibilityLabel"))

                Button(action: onNotifications) {
                    ZStack(alignment: .topTrailing) {
                        Image(systemName: "bell")
                            .font(.system(size: 22, weight: .regular))
                            .foregroundStyle(.white)
                            .frame(width: 24, height: 24)

                        UnreadDotBadge(hasUnread: hasUnreadNotifications)
                            .offset(x: 2, y: -2)
                    }
                    .frame(minWidth: 44, minHeight: 44)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("HomeHeader.notificationsButton")
                .accessibilityLabel(bellAccessibilityLabel)
                .accessibilityAddTraits(.isButton)
            }
            .padding(.top, 12) // chip y=64 vs logo y=52 (Δ = 12 pt) — Figma offset between logo top and cluster top.
        }
        .frame(height: 44)
    }

    private var bellAccessibilityLabel: Text {
        // Spec §Behavioral Requirements bell label rules — singular /
        // plural / empty. US1 doesn't have the unreadCount yet, so we
        // collapse to the binary state with the existing keys; T068
        // (US3) extends this to the full count-aware label.
        Text(hasUnreadNotifications ? "home.bell.unread.singular" : "home.bell.empty")
    }
}
