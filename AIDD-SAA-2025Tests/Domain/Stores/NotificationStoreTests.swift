import RxRelay
import RxSwift
import XCTest
@testable import AIDD_SAA_2025

final class NotificationStoreTests: XCTestCase {

    func test_initialValue_zero_byDefault() {
        let store = NotificationStore()
        XCTAssertEqual(store.unreadCount.value, 0)
    }

    func test_initialValue_negative_clampsToZero() {
        let store = NotificationStore(initial: -5)
        XCTAssertEqual(store.unreadCount.value, 0)
    }

    func test_set_negativeClampsToZero() {
        let store = NotificationStore(initial: 3)
        store.set(-2)
        XCTAssertEqual(store.unreadCount.value, 0)
    }

    func test_hasUnreadObservable_reflectsCount() {
        let store = NotificationStore()
        let bag = DisposeBag()
        var received: [Bool] = []
        store.hasUnreadObservable
            .subscribe(onNext: { received.append($0) })
            .disposed(by: bag)

        store.set(0)   // duplicate of initial — distinctUntilChanged drops it
        store.set(1)
        store.set(2)
        store.set(0)

        XCTAssertEqual(received, [false, true, false])
    }
}
