import RxRelay
import RxSwift
import XCTest
@testable import AIDD_SAA_2025

final class SetActiveTabUseCaseTests: XCTestCase {

    func test_execute_setsRouter_onSwitch() {
        let router = TabRouter(initial: .saa)
        let sut = SetActiveTabUseCase(router: router)

        sut.execute(.kudos)
        XCTAssertEqual(router.selectedTab.value, .kudos)
    }

    func test_execute_emitsReTap_onSameTab() {
        let router = TabRouter(initial: .saa)
        let bag = DisposeBag()
        var reTaps: [AppTab] = []
        router.activeTabReTapped
            .subscribe(onNext: { reTaps.append($0) })
            .disposed(by: bag)

        let sut = SetActiveTabUseCase(router: router)
        sut.execute(.saa)

        XCTAssertEqual(reTaps, [.saa])
    }
}
