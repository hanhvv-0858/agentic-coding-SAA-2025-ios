import RxBlocking
import RxRelay
import RxSwift
import XCTest
@testable import AIDD_SAA_2025

final class TabRouterTests: XCTestCase {

    func test_initialValue_isSAATab() {
        let router = TabRouter()
        XCTAssertEqual(router.selectedTab.value, .saa)
    }

    func test_setSwitchesTab() {
        let router = TabRouter()
        router.set(.kudos)
        XCTAssertEqual(router.selectedTab.value, .kudos)
    }

    func test_setEmitsViaObservable() throws {
        let router = TabRouter()
        let bag = DisposeBag()
        var received: [AppTab] = []
        router.selectedTabObservable
            .subscribe(onNext: { received.append($0) })
            .disposed(by: bag)

        router.set(.awards)
        router.set(.profile)

        XCTAssertEqual(received, [.saa, .awards, .profile])
    }

    func test_setSameTab_doesNotEmitOnObservable() {
        let router = TabRouter(initial: .kudos)
        let bag = DisposeBag()
        var received: [AppTab] = []
        router.selectedTabObservable
            .subscribe(onNext: { received.append($0) })
            .disposed(by: bag)

        router.set(.kudos)

        XCTAssertEqual(received, [.kudos]) // initial only
    }

    func test_setSameTab_emitsReTapEvent() {
        let router = TabRouter(initial: .saa)
        let bag = DisposeBag()
        var reTaps: [AppTab] = []
        router.activeTabReTapped
            .subscribe(onNext: { reTaps.append($0) })
            .disposed(by: bag)

        router.set(.saa)

        XCTAssertEqual(reTaps, [.saa])
    }

    func test_notifyTap_routesToSetOrReTap() {
        let router = TabRouter(initial: .saa)
        let bag = DisposeBag()
        var switches: [AppTab] = []
        var reTaps: [AppTab] = []
        router.selectedTabObservable
            .subscribe(onNext: { switches.append($0) })
            .disposed(by: bag)
        router.activeTabReTapped
            .subscribe(onNext: { reTaps.append($0) })
            .disposed(by: bag)

        router.notifyTap(.kudos)   // switch
        router.notifyTap(.kudos)   // re-tap
        router.notifyTap(.profile) // switch

        XCTAssertEqual(switches, [.saa, .kudos, .profile])
        XCTAssertEqual(reTaps, [.kudos])
    }
}
