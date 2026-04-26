import Foundation
import RxCocoa
import RxRelay
import RxSwift

protocol NotFoundViewModel: AnyObject {
    // Inputs
    var primaryTapped: PublishRelay<Void> { get }

    // Outputs — emits the route the caller should reset to. Computed
    // from the live AuthStore state at the moment of the tap, per
    // plan.md (Login if signed-out, Home if signed-in).
    var navigateRoot: Signal<AppRoute> { get }
}

nonisolated final class NotFoundViewModelImpl: NotFoundViewModel {

    let primaryTapped = PublishRelay<Void>()

    var navigateRoot: Signal<AppRoute> { navigateRootRelay.asSignal() }
    private let navigateRootRelay = PublishRelay<AppRoute>()

    private let authStore: AuthStoring
    private let disposeBag = DisposeBag()

    init(authStore: AuthStoring) {
        self.authStore = authStore

        primaryTapped
            .withLatestFrom(authStore.state.asObservable())
            .map { state -> AppRoute in
                switch state {
                case .signedIn:
                    return .home
                case .signedOut, .unknown:
                    return .login
                }
            }
            .bind(to: navigateRootRelay)
            .disposed(by: disposeBag)
    }
}
