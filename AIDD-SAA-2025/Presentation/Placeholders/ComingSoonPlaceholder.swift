import os
import SwiftUI

/// Single M2 placeholder used for every `AppRoute` case whose real
/// destination ships in a later milestone:
/// - `.compose`     — FAB pen tap zone (M4 swaps to real composer).
/// - `.kudosFeed`   — FAB Sun*Kudos tap zone, Kudos tab, Kudos
///                    section "Chi tiết" (M4 swaps to real feed).
/// - `.search`      — header search icon (M5 swaps to real search).
/// - `.profile`     — Profile tab (M3 swaps to real profile).
///
/// Each variant maps to localised copy + a back CTA. Re-uses M1
/// `ErrorStateView` so the screen has consistent typography.
struct ComingSoonPlaceholder: View {

    enum Variant: String {
        case compose
        case kudosFeed
        case search
        case profile
        /// Temporary M2 placeholder until the sibling Notifications inbox
        /// spec lands. The sibling PR replaces this branch in `RootView`.
        case notifications
    }

    let variant: Variant
    let onBack: () -> Void

    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                TopNavigation()

                Spacer()

                ErrorStateView(
                    title: "awards.placeholder.title",
                    subtitle: "awards.placeholder.subtitle",
                    illustrationSystemName: illustration,
                    primaryButtonTitle: "awards.placeholder.primaryButton",
                    onPrimaryTap: onBack
                )

                Spacer()
            }
        }
        .accessibilityIdentifier("ComingSoonPlaceholder.\(variant.rawValue)")
        .onAppear {
            Log.home.info("placeholder.\(variant.rawValue, privacy: .public)")
        }
    }

    private var illustration: String {
        switch variant {
        case .compose:       return "square.and.pencil"
        case .kudosFeed:     return "hands.sparkles"
        case .search:        return "magnifyingglass"
        case .profile:       return "person.crop.circle"
        case .notifications: return "bell"
        }
    }
}
