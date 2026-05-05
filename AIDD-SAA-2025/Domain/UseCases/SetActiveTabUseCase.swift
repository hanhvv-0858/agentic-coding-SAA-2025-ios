import Foundation

protocol SetActiveTabUseCaseProtocol {
    /// Invoked by `BottomTabBar` whenever a tab is tapped. Wraps
    /// `TabRouter.notifyTap(_:)` (which auto-routes to set vs
    /// re-tap based on the current selected tab). Kept thin so the
    /// future analytics + deeplink-aware tab switching live in one
    /// place.
    func execute(_ tab: AppTab)
}

nonisolated final class SetActiveTabUseCase: SetActiveTabUseCaseProtocol {
    private let router: TabRouting

    init(router: TabRouting) {
        self.router = router
    }

    func execute(_ tab: AppTab) {
        router.notifyTap(tab)
    }
}
