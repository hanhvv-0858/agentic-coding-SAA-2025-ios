import Combine
import RxCocoa
import RxRelay
import RxSwift
import SwiftUI
import UIKit

struct RootView: View {
    @StateObject private var routeState: RootStateAdapter
    @StateObject private var loginState: LoginStateAdapter
    private let accessDeniedViewModel: AccessDeniedViewModel
    private let notFoundViewModel: NotFoundViewModel
    private let authRouterBinder: AuthRouterBinder
    private let restoreSessionUseCase: RestoreSessionUseCaseProtocol
    private let router: AppRouting
    private let oauthRedirectURL: URL

    init(container: ContainerProtocol) {
        let loginAdapter = LoginStateAdapter(viewModel: container.makeLoginViewModel())
        _routeState = StateObject(wrappedValue: RootStateAdapter(router: container.router))
        _loginState = StateObject(wrappedValue: loginAdapter)
        self.accessDeniedViewModel = container.makeAccessDeniedViewModel()
        self.notFoundViewModel = container.makeNotFoundViewModel()
        self.authRouterBinder = container.authRouterBinder
        self.restoreSessionUseCase = container.makeRestoreSessionUseCase()
        self.router = container.router
        self.oauthRedirectURL = container.config.oauthRedirectURL
    }

    var body: some View {
        Group {
            switch routeState.route {
            case .login:
                LoginView(state: loginState)
            case .accessDenied:
                AccessDeniedView(viewModel: accessDeniedViewModel)
            case .notFound(_):
                NotFoundView(viewModel: notFoundViewModel)
            case .home:
                HomePlaceholder()
            default:
                LoginView(state: loginState)
            }
        }
        .onAppear {
            authRouterBinder.start()
            wireNavigationSignals()
            restoreSessionOnce()
        }
        .onOpenURL { url in handleIncoming(url) }
        // US4 AS1–AS3: re-evaluate the cached session every time the
        // app comes back to the foreground. The repository decides
        // whether to silent-refresh, return the cached session, or
        // surface `.signedOut` (which the binder routes to Login).
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            restoreSessionOnce()
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

private struct HomePlaceholder: View {
    var body: some View {
        VStack(spacing: 12) {
            Text("Home").font(.title2)
            Text("M2 will replace this with the SAA tab + countdown.")
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}
