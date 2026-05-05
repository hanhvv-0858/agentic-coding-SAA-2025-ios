import Combine
import RxCocoa
import RxRelay
import RxSwift
import SwiftUI
import UIKit

struct RootView: View {
    @StateObject private var routeState: RootStateAdapter
    @StateObject private var loginState: LoginStateAdapter
    @StateObject private var tabBarState: BottomTabBarState
    @StateObject private var homeState: HomeStateAdapter
    private let accessDeniedViewModel: AccessDeniedViewModel
    private let notFoundViewModel: NotFoundViewModel
    private let authRouterBinder: AuthRouterBinder
    private let restoreSessionUseCase: RestoreSessionUseCaseProtocol
    private let router: AppRouting
    private let tabRouter: TabRouting
    private let oauthRedirectURL: URL

    init(container: ContainerProtocol) {
        let loginAdapter = LoginStateAdapter(viewModel: container.makeLoginViewModel())
        let homeAdapter = HomeStateAdapter(viewModel: container.makeHomeViewModel())
        _routeState = StateObject(wrappedValue: RootStateAdapter(router: container.router))
        _loginState = StateObject(wrappedValue: loginAdapter)
        _tabBarState = StateObject(wrappedValue: BottomTabBarState(router: container.tabRouter))
        _homeState = StateObject(wrappedValue: homeAdapter)
        self.accessDeniedViewModel = container.makeAccessDeniedViewModel()
        self.notFoundViewModel = container.makeNotFoundViewModel()
        self.authRouterBinder = container.authRouterBinder
        self.restoreSessionUseCase = container.makeRestoreSessionUseCase()
        self.router = container.router
        self.tabRouter = container.tabRouter
        self.oauthRedirectURL = container.config.oauthRedirectURL
    }

    var body: some View {
        Group {
            switch routeState.route {
            // Pre-auth flow — no tab bar.
            case .login:
                LoginView(state: loginState)
            case .accessDenied:
                AccessDeniedView(viewModel: accessDeniedViewModel)
            case .notFound:
                NotFoundView(viewModel: notFoundViewModel)

            // Authenticated tab roots & destinations — wrapped in the
            // tab-bar shell. Every case resolves to a concrete view; M2
            // removes the M1 `default → LoginView` fall-through so a
            // forgotten route can never silently land on Login.
            case .home:
                authenticatedShell {
                    HomeView(
                        state: homeState,
                        onLanguageTap: { /* US5 — T077 wires LanguagePickerDropdown */ },
                        onSearchTap: { router.reset(to: .searchSunner) },
                        onNotificationsTap: { router.reset(to: .notifications) },
                        onNavigate: { route in router.reset(to: route) },
                        onRetryFeed: {
                            // US6 will replace this with pullToRefresh.accept(())
                            homeState.viewModel.viewAppeared.accept(())
                        }
                    )
                }
            case .notifications:
                // Sibling Notifications spec lands a real inbox in M2 —
                // this branch is replaced by that PR.
                authenticatedShell {
                    ComingSoonPlaceholder(variant: .notifications, onBack: backToHome)
                }
            case .profileMe, .profileOther:
                authenticatedShell {
                    ComingSoonPlaceholder(variant: .profile, onBack: backToHome)
                }
            case .awardDetail(let kind):
                authenticatedShell {
                    AwardDetailPlaceholder(kind: kind, onBack: backToHome)
                }
            case .sunKudos, .allKudos, .viewKudo:
                authenticatedShell {
                    ComingSoonPlaceholder(variant: .kudosFeed, onBack: backToHome)
                }
            case .writeKudo:
                authenticatedShell {
                    ComingSoonPlaceholder(variant: .compose, onBack: backToHome)
                }
            case .searchSunner:
                authenticatedShell {
                    ComingSoonPlaceholder(variant: .search, onBack: backToHome)
                }
            case .secretBox, .theLe, .communityStandards:
                // Out-of-scope for M2 — sibling clusters (M5+) wire each
                // to their own real view.
                authenticatedShell {
                    ComingSoonPlaceholder(variant: .kudosFeed, onBack: backToHome)
                }
            }
        }
        .onAppear {
            authRouterBinder.start()
            wireNavigationSignals()
            restoreSessionOnce()
        }
        .onOpenURL { url in handleIncoming(url) }
        // US8: tab bar tap → push the AppRoute that the tab represents.
        // Active-re-tap doesn't change `selectedTab` (TabRouter routes it
        // through `activeTabReTapped` instead), so this only fires on
        // genuine tab switches.
        .onChange(of: tabBarState.selectedTab) { tab in
            router.reset(to: route(for: tab))
        }
        // US8 AS4: tap the active tab — if user is NOT on the tab's
        // primary route (e.g. drilled into award detail from Home and
        // re-tapping SAA), reset to the primary route. If they ARE
        // on it, HomeVM's `scrollTo` (driven by the same
        // `tabRouter.activeTabReTapped`) handles the scroll-to-top.
        .onChange(of: tabBarState.pendingReTap) { tab in
            guard let tab else { return }
            let primary = route(for: tab)
            if routeState.route != primary {
                router.reset(to: primary)
            }
            tabBarState.clearPendingReTap()
        }
        // US4 AS1–AS3: re-evaluate the cached session every time the
        // app comes back to the foreground. The repository decides
        // whether to silent-refresh, return the cached session, or
        // surface `.signedOut` (which the binder routes to Login).
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            restoreSessionOnce()
        }
    }

    @ViewBuilder
    private func authenticatedShell<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .safeAreaInset(edge: .bottom, spacing: 0) {
                // Paint the BottomTabBar's FULL band (BrandOnCream +
                // ultraThinMaterial + cream-15 %) behind the bar AND
                // extend it through the bottom safe area (home-indicator
                // zone). `safeAreaInset` reserves only the bar's 72 pt
                // intrinsic size; without this the home-indicator zone
                // is painted by whatever the screen content uses
                // (e.g. ComingSoonPlaceholder fills `.systemBackground`
                // through the safe area), leaving a visible gap. Plain
                // `BrandOnCream` alone leaves a color seam against the
                // bar's cream-tinted band, so we replicate the full
                // layered fill here. Top corners are NOT rounded on this
                // extending band — only the bar's own background carries
                // the 20 pt top-leading/trailing radius.
                BottomTabBar(state: tabBarState)
                    .background(alignment: .bottom) {
                        ZStack {
                            Color("BrandOnCream")
                            Rectangle().fill(.ultraThinMaterial)
                            Rectangle().fill(Color("BrandCream").opacity(0.15))
                        }
                        // Same 20 pt top-only rounded corners as the
                        // bar's own band — without this clip the
                        // extending background fills the square corner
                        // pixels OUTSIDE the band's rounded curve, so
                        // the bar visually reads as having square top
                        // corners (and looks wider at the very edges).
                        .clipShape(
                            UnevenRoundedRectangle(
                                topLeadingRadius: 20,
                                bottomLeadingRadius: 0,
                                bottomTrailingRadius: 0,
                                topTrailingRadius: 20
                            )
                        )
                        .ignoresSafeArea(edges: .bottom)
                    }
            }
    }

    private func backToHome() {
        router.reset(to: .home)
    }

    /// Maps each `AppTab` to its primary `AppRoute`. Used by both the
    /// tab-switch handler and the active-re-tap handler.
    private func route(for tab: AppTab) -> AppRoute {
        switch tab {
        case .saa:     return .home
        case .awards:  return .awardDetail(kind: .topTalent)
        case .kudos:   return .sunKudos
        case .profile: return .profileMe(anchor: nil)
        }
    }

    /// Forward OAuth callback URLs to the login flow; everything else
    /// falls through to the router (deep-link queue lives there).
    private func handleIncoming(_ url: URL) {
        if url.scheme == oauthRedirectURL.scheme && url.host == oauthRedirectURL.host {
            loginState.viewModel.oauthCallback.accept(url)
        }
    }

    private func wireNavigationSignals() {
        loginState.viewModel.navigateAccessDenied
            .emit(onNext: { [router] in router.reset(to: .accessDenied) })
            .disposed(by: routeState.disposeBag)

        accessDeniedViewModel.navigateLogin
            .emit(onNext: { [router] in router.reset(to: .login) })
            .disposed(by: routeState.disposeBag)

        notFoundViewModel.navigateRoot
            .emit(onNext: { [router] route in router.reset(to: route) })
            .disposed(by: routeState.disposeBag)
    }

    private func restoreSessionOnce() {
        _ = restoreSessionUseCase.execute().subscribe()
    }
}

private final class RootStateAdapter: ObservableObject {
    @Published var route: AppRoute
    let disposeBag = DisposeBag()

    init(router: AppRouting) {
        self.route = router.root.value
        router.rootObservable
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] in self?.route = $0 })
            .disposed(by: disposeBag)
    }
}

