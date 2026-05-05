import SwiftUI

/// Horizontal scrollable strip of award cards per design-style.md §7.3.
/// Container is 1040 pt wide (extends past the 375 pt screen) with
/// `LazyHStack(spacing: 16)` so off-screen cards aren't loaded eagerly.
///
/// Renders 4 states (per spec §Component Behavior):
/// - `.loading` — 3 skeleton placeholder cards
/// - `.loaded(rows)` — real `AwardCardView` per row
/// - `.empty` — single line "Awards will be announced soon."
/// - `.error` — inline retry row
struct AwardCardsRow: View {

    let state: AwardsTeaserState
    let language: AppLanguage
    let onCardTap: (AwardKind) -> Void
    let onRetry: () -> Void

    var body: some View {
        switch state {
        case .loading:
            loadingSkeleton
        case .loaded(let rows):
            loadedRow(rows)
        case .empty:
            emptyState
        case .error:
            errorState
        }
    }

    private var loadingSkeleton: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 16) {
                ForEach(0..<3, id: \.self) { _ in
                    VStack(alignment: .leading, spacing: 12) {
                        RoundedRectangle(cornerRadius: 11.43)
                            .fill(Color.white.opacity(0.08))
                            .frame(width: 160, height: 160)
                        VStack(alignment: .leading, spacing: 2) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.white.opacity(0.10))
                                .frame(width: 120, height: 20)
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.white.opacity(0.06))
                                .frame(width: 160, height: 60)
                        }
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white.opacity(0.08))
                            .frame(width: 84, height: 32)
                    }
                    .frame(width: 160)
                }
            }
        }
        .accessibilityElement()
        .accessibilityLabel(Text("home.awards.title"))
        .accessibilityHint(Text("home.awards.loading"))
    }

    private func loadedRow(_ rows: [AwardTeaser]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 16) {
                ForEach(rows.sorted(by: { $0.displayOrder < $1.displayOrder })) { teaser in
                    AwardCardView(
                        teaser: teaser,
                        language: language,
                        onTap: { onCardTap(teaser.kind) }
                    )
                }
            }
        }
    }

    private var emptyState: some View {
        Text("home.awards.empty")
            .font(.system(size: 14, weight: .light))
            .tracking(0.25)
            .foregroundStyle(.white.opacity(0.7))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 24)
    }

    private var errorState: some View {
        Button(action: onRetry) {
            Text("home.awards.error")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color("BrandCream"))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 24)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("AwardCardsRow.retry")
    }
}
