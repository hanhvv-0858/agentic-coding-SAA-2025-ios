import os
import SwiftUI

/// M2 placeholder for `AppRoute.awardDetail(kind:)`. M4 swaps the binding
/// to the real `AwardDetailView(kind:)` against the same route case —
/// no nav-contract change required (per spec §Q2 resolution).
///
/// Re-uses the M1 `ErrorStateView` organism so the screen has a back
/// CTA and consistent typography. Analytics distinguishes "M2
/// placeholder tap" from real detail tap so PM can measure handoff
/// readiness.
struct AwardDetailPlaceholder: View {

    let kind: AwardKind
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
                    illustrationSystemName: "trophy",
                    primaryButtonTitle: "awards.placeholder.primaryButton",
                    onPrimaryTap: onBack
                )

                Spacer()
            }
        }
        .accessibilityIdentifier("AwardDetailPlaceholder.\(kind.rawValue)")
        .onAppear {
            Log.home.info("placeholder.award_detail kind=\(kind.rawValue, privacy: .public)")
        }
    }
}
