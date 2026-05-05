import Combine
import SwiftUI

/// Organism: the app-wide 4-tab bottom navigation. Owned by `RootView`,
/// consumed by every authenticated screen. Pure presentation — taps are
/// forwarded to the injected `TabRouting` store; the active tab is read
/// from the same store.
///
/// Visual tokens (height, icon set, active/inactive colors, indicator)
/// are placeholders for M2; the final values land at T109 (US8
/// visual-parity gate).
struct BottomTabBar: View {

    @ObservedObject var state: BottomTabBarState

    var body: some View {
        HStack(spacing: 0) {
            ForEach(AppTab.allCases, id: \.self) { tab in
                Button(action: { state.tap(tab) }) {
                    VStack(spacing: 4) {
                        Image(systemName: iconName(for: tab))
                            .font(.system(size: 22, weight: .regular))
                        Text(label(for: tab))
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundStyle(state.selectedTab == tab ? Color("BrandCream") : Color.white.opacity(0.65))
                    .frame(width: 60, height: 44)
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("BottomTabBar.\(tab.rawValue)")
                .accessibilityLabel(Text(label(for: tab)))
                .accessibilityAddTraits(state.selectedTab == tab ? [.isButton, .isSelected] : .isButton)
            }
        }
        .frame(height: 72)
        .padding(.horizontal, 24)
        // Per design-style §10: cream 15% over a darker base + frosted
        // blur, top corners rounded 20 pt. The dark base layer
        // (BrandOnCream) is opaque so the bar reads as a solid band —
        // without it, `.ultraThinMaterial` + 15 % cream is still
        // transparent enough that ScrollView content above bleeds
        // through visually. The home-indicator zone below this 72 pt
        // band is painted by `RootView.authenticatedShell`'s background.
        .background(alignment: .top) {
            ZStack {
                Color("BrandOnCream")
                Rectangle().fill(.ultraThinMaterial)
                Rectangle().fill(Color("BrandCream").opacity(0.15))
            }
            .clipShape(
                UnevenRoundedRectangle(
                    topLeadingRadius: 20,
                    bottomLeadingRadius: 0,
                    bottomTrailingRadius: 0,
                    topTrailingRadius: 20
                )
            )
        }
    }

    private func iconName(for tab: AppTab) -> String {
        switch tab {
        case .saa:     return "house.fill"
        case .awards:  return "trophy.fill"
        case .kudos:   return "hands.sparkles.fill"
        case .profile: return "person.crop.circle.fill"
        }
    }

    private func label(for tab: AppTab) -> LocalizedStringKey {
        switch tab {
        case .saa:     return "tab.saa"
        case .awards:  return "tab.awards"
        case .kudos:   return "tab.kudos"
        case .profile: return "tab.profile"
        }
    }
}

import RxRelay
import RxSwift

/// Combine bridge for `BottomTabBar`. Subscribes to `TabRouting` and
/// re-publishes the selected tab + active-re-tap events; forwards taps
/// back through the store.
final class BottomTabBarState: ObservableObject {
    @Published private(set) var selectedTab: AppTab
    /// One-shot @Published value re-emitted when `TabRouter.activeTabReTapped`
    /// fires. RootView consumes via `.onChange` and resets to `nil`.
    @Published var pendingReTap: AppTab?

    private let router: TabRouting
    private let bag = DisposeBag()

    init(router: TabRouting) {
        self.router = router
        self.selectedTab = router.selectedTab.value
        router.selectedTabObservable
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] in self?.selectedTab = $0 })
            .disposed(by: bag)
        router.activeTabReTapped
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] tab in self?.pendingReTap = tab })
            .disposed(by: bag)
    }

    func tap(_ tab: AppTab) {
        router.notifyTap(tab)
    }

    func clearPendingReTap() { pendingReTap = nil }
}
