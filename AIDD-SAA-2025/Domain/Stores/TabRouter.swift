import Foundation
import RxRelay
import RxSwift

protocol TabRouting: AnyObject {
    var selectedTab: BehaviorRelay<AppTab> { get }
    var selectedTabObservable: Observable<AppTab> { get }
    var activeTabReTapped: Observable<AppTab> { get }
    func set(_ tab: AppTab)
    func notifyTap(_ tab: AppTab)
}

/// Owns the currently-active bottom tab and broadcasts tap-while-active
/// events. Consumed by `BottomTabBar` (writer) and `RootView` (reader).
nonisolated final class TabRouter: TabRouting {
    let selectedTab: BehaviorRelay<AppTab>

    var selectedTabObservable: Observable<AppTab> {
        selectedTab.asObservable().distinctUntilChanged()
    }

    var activeTabReTapped: Observable<AppTab> { reTapRelay.asObservable() }

    private let reTapRelay = PublishRelay<AppTab>()

    init(initial: AppTab = .saa) {
        self.selectedTab = BehaviorRelay(value: initial)
    }

    func set(_ tab: AppTab) {
        guard selectedTab.value != tab else {
            reTapRelay.accept(tab)
            return
        }
        selectedTab.accept(tab)
    }

    /// Distinguishes "tap to switch" from "tap while already active". The
    /// caller decides which of `set(_:)` / `notifyTap(_:)` matches the
    /// gesture. `BottomTabBar` always calls `set(_:)` — the relay folds
    /// the re-tap case automatically.
    func notifyTap(_ tab: AppTab) {
        if selectedTab.value == tab {
            reTapRelay.accept(tab)
        } else {
            selectedTab.accept(tab)
        }
    }
}
