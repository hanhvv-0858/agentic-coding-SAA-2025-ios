import Foundation
import RxRelay
import RxSwift

enum AuthState: Equatable {
    case unknown
    case signedOut
    case signedIn(AuthSession)
}

protocol AuthStoring: AnyObject {
    var state: BehaviorRelay<AuthState> { get }
    var stateObservable: Observable<AuthState> { get }
}

nonisolated final class AuthStore: AuthStoring {
    let state: BehaviorRelay<AuthState>

    var stateObservable: Observable<AuthState> {
        state.asObservable().distinctUntilChanged()
    }

    init(initial: AuthState = .unknown) {
        self.state = BehaviorRelay(value: initial)
    }
}
