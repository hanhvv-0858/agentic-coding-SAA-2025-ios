import SwiftUI

/// Award teaser card per design-style.md §7.4. Layout: 160 × 298 pt
/// vertical column with 12 pt gap between picture / text / button.
///
/// Picture cell: 160 × 160 pt, 11.43 pt corner radius, 0.455 pt cream
/// border, dark drop + pale-yellow `#FAE287` glow shadow.
struct AwardCardView: View {

    let teaser: AwardTeaser
    let language: AppLanguage
    let onTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            picture
            textBlock
            detailButton
        }
        .frame(width: 160)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(combinedAccessibilityLabel))
        .accessibilityAddTraits(.isButton)
    }

    // MARK: - Picture

    private var picture: some View {
        ZStack {
            // 160×160 raster background. Asset key matches DB
            // `awards.artwork_asset_key` (e.g. `award_top_talent`).
            Image("awards/\(teaser.artworkAssetKey)")
                .resizable()
                .scaledToFill()
                .frame(width: 160, height: 160)
                .clipped()
        }
        .frame(width: 160, height: 160)
        .background(Color("BrandOnCream"))
        .overlay(
            RoundedRectangle(cornerRadius: 11.43)
                .stroke(Color("BrandCream"), lineWidth: 0.455)
        )
        .clipShape(RoundedRectangle(cornerRadius: 11.43))
        .shadow(color: .black.opacity(0.25), radius: 1.905, x: 0, y: 1.905)
        .shadow(color: Color(red: 250/255, green: 226/255, blue: 135/255).opacity(0.6), radius: 2.857, x: 0, y: 0)
        .accessibilityHidden(true)
    }

    // MARK: - Text block

    private var textBlock: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(teaser.localisedTitle(for: language))
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color("BrandCream"))
                .lineLimit(1)
                .frame(width: 160, alignment: .leading)

            Text(teaser.localisedDescription(for: language))
                .font(.system(size: 14, weight: .light))
                .tracking(0.25)
                .foregroundStyle(.white)
                .lineLimit(3)
                .truncationMode(.tail)
                .frame(width: 160, alignment: .leading)
        }
    }

    // MARK: - Detail button

    private var detailButton: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                Text("home.kudos.detailButton")  // shared "Chi tiết" string
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white)
                Image(systemName: "arrow.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 24, height: 24)
            }
            .padding(.vertical, 10)
            .frame(width: 84, height: 32)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("AwardCardView.detail.\(teaser.kind.rawValue)")
    }

    // MARK: - Accessibility

    private var combinedAccessibilityLabel: String {
        // Spec §Behavioral Requirements: "\(awardName). \(awardTagline). Nhấn để xem chi tiết."
        let tail = language == .vi ? "Nhấn để xem chi tiết." : "Tap for details."
        let title = teaser.localisedTitle(for: language)
        let desc = teaser.localisedDescription(for: language)
        return "\(title). \(desc) \(tail)"
    }
}
