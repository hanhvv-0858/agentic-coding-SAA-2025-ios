import Foundation
import RxRelay
import RxSwift
import os

/// Listens to `AuthStore` and drives `AppRouter.root` accordingly.
///
/// Decoupling this from `AppRouter` keeps the router a passive holder
/// (so other features can drive routes too) and isolates the
/// auth → navigation policy in one testable place.
nonisolated final class AuthRouterBinder {

    private let authStore: AuthStoring
    private let router: AppRouting
    private let disposeBag = DisposeBag()

    init(authStore: AuthStoring, router: AppRouting) {
        self.authStore = authStore
        self.router = router
    }

    func start() {
        authStore.stateObservable
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] state in
                guard let self else { return }
                switch state {
                case .unknown:
                    return
                case .signedOut:
                    // US2: when the disallowed-domain pipeline calls
                    // signOut, we want to land on Access denied — NOT
                    // bounce back to Login. The Login VM explicitly
                    // resets the router to `.accessDenied`; this guard
                    // prevents the AuthStore signal from overriding it.
                    if self.router.root.value != .accessDenied {
                        self.router.reset(to: .login)
                    }
                case .signedIn:
                    self.router.reset(to: .home)
                }
            })
            .disposed(by: disposeBag)

        Log.auth.info("AuthRouterBinder started")
    }
}
