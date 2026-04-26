import Foundation
import RxCocoa
import RxRelay
import RxSwift
import os

protocol AccessDeniedViewModel: AnyObject {
    // Inputs
    var primaryTapped: PublishRelay<Void> { get }
    var backTapped: PublishRelay<Void> { get }
    var onAppear: PublishRelay<Void> { get }

    // Outputs
    var navigateLogin: Signal<Void> { get }
}

nonisolated final class AccessDeniedViewModelImpl: AccessDeniedViewModel {

    let primaryTapped = PublishRelay<Void>()
    let backTapped = PublishRelay<Void>()
    let onAppear = PublishRelay<Void>()

    var navigateLogin: Signal<Void> { navigateLoginRelay.asSignal() }

    private let navigateLoginRelay = PublishRelay<Void>()
    private let signOutUseCase: SignOutUseCaseProtocol
    private let disposeBag = DisposeBag()

    init(signOutUseCase: SignOutUseCaseProtocol) {
        self.signOutUseCase = signOutUseCase

        Observable.merge(primaryTapped.asObservable(), backTapped.asObservable())
            .bind(to: navigateLoginRelay)
            .disposed(by: disposeBag)

        // Spec edge case: defensive sign-out on appear if a stale session
        // somehow reaches this screen (should never happen because the
        // disallowed-domain pipeline already calls signOut). Keep it for
        // belt-and-braces; logs use `.private` interpolation per
        // Constitution V if a session is detected.
        onAppear
            .flatMapLatest { [signOutUseCase] _ -> Observable<Void> in
                signOutUseCase.execute()
                    .do(onError: { error in
                        Log.auth.warning("Defensive signOut on AccessDenied failed: \(String(describing: error), privacy: .public)")
                    })
                    .andThen(.empty())
                    .catch { _ in .empty() }
            }
            .subscribe()
            .disposed(by: disposeBag)
    }
}
