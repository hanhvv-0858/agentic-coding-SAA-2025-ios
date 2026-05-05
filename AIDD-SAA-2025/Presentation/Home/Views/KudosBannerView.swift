import SwiftUI

/// Kudos section per design-style.md §8. Container is 335 × 490 pt
/// vertical column with gap 24 pt — header / banner image / note
/// paragraph / "Chi tiết" CTA.
///
/// State-driven rendering:
/// - `.loading` — banner skeleton, note + button hidden
/// - `.loaded(highlight)` — bundled `KudosBanner` asset (M2) or
///   future remote URL (M4)
/// - `.empty` — fallback `#0F0F0F` block + "KUDOS" wordmark, never
///   blocks page render
struct KudosBannerView: View {

    let state: KudosBannerState
    let onDetailTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            sectionHeader
            banner
            noteParagraph
            detailButton
        }
    }

    // MARK: - Header

    private var sectionHeader: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("home.kudos.category")
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(.white)
            Rectangle()
                .fill(Color(red: 46/255, green: 57/255, blue: 64/255))   // #2E3940
                .frame(height: 1)
            Text("home.kudos.title")
                .font(.system(size: 22, weight: .medium))
                .foregroundStyle(Color("BrandCream"))
        }
    }

    // MARK: - Banner

    @ViewBuilder
    private var banner: some View {
        switch state {
        case .loading:
            RoundedRectangle(cornerRadius: 4.65)
                .fill(Color(red: 15/255, green: 15/255, blue: 15/255))   // #0F0F0F
                .frame(height: 145)
                .accessibilityHidden(true)
        case .loaded:
            // M2: bundled `KudosBanner` asset + `kudos_logo` wordmark
            // overlaid bottom-right per design. M4 swaps the banner
            // to remote via `highlight.bannerImageURL` when Q7 lands.
            ZStack {
                Image("KudosBanner")
                    .resizable()
                    .scaledToFill()
                    .frame(height: 145)
                    .clipped()
            }
            .frame(maxWidth: .infinity)
            .frame(height: 145)
            .background(Color(red: 15/255, green: 15/255, blue: 15/255))
            .overlay(alignment: .bottomTrailing) {
                Image("kudos_logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 96)
                    .padding(.trailing, 36)
                    .padding(.bottom, 68)
                    .accessibilityHidden(true)
            }
            .clipShape(RoundedRectangle(cornerRadius: 4.65))
            .accessibilityLabel(Text("home.kudos.title"))
        case .empty:
            // Image-load failure fallback: coloured-block + KUDOS
            // wordmark (per spec §Component Behavior — never blocks
            // page render).
            ZStack {
                RoundedRectangle(cornerRadius: 4.65)
                    .fill(Color(red: 15/255, green: 15/255, blue: 15/255))
                Image("kudos_logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120)
            }
            .frame(height: 145)
            .accessibilityHidden(true)
        }
    }

    // MARK: - Note paragraph

    private var noteParagraph: some View {
        Text("home.kudos.note")
            .font(.system(size: 14, weight: .light))
            .tracking(0.25)
            .foregroundStyle(.white)
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
    }

    // MARK: - Detail button

    private var detailButton: some View {
        Button(action: onDetailTap) {
            HStack(spacing: 8) {
                Text("home.kudos.detailButton")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color("BrandOnCream"))
                Image(systemName: "arrow.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color("BrandOnCream"))
                    .frame(width: 24, height: 24)
            }
            .frame(width: 160, height: 40)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color("BrandCream"))
            )
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("KudosBannerView.detail")
        .accessibilityLabel(Text("home.kudos.detailButton"))
    }
}
