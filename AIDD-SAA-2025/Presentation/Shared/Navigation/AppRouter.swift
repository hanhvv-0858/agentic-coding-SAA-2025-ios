import Foundation
import RxRelay
import RxSwift

protocol AppRouting: AnyObject {
    var root: BehaviorRelay<AppRoute> { get }
    var rootObservable: Observable<AppRoute> { get }
    func reset(to route: AppRoute)
}

final class AppRouter: AppRouting {
    let root: BehaviorRelay<AppRoute>

    var rootObservable: Observable<AppRoute> {
        root.asObservable().distinctUntilChanged()
    }

    init(initial: AppRoute = .login) {
        self.root = BehaviorRelay(value: initial)
    }

    func reset(to route: AppRoute) {
        root.accept(route)
    }
}
