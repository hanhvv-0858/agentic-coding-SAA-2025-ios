import RxBlocking
import RxCocoa
import RxRelay
import RxSwift
import XCTest
@testable import AIDD_SAA_2025

final class NotFoundViewModelTests: XCTestCase {

    private var disposeBag: DisposeBag!

    override func setUp() {
        super.setUp()
        disposeBag = DisposeBag()
    }

    override func tearDown() {
        disposeBag = nil
        super.tearDown()
    }

    private func collect<T>(_ source: Observable<T>) -> () -> [T] {
        var collected: [T] = []
        source.subscribe(onNext: { collected.append($0) }).disposed(by: disposeBag)
        return { collected }
    }

    func test_primaryTap_whenSignedOut_routesToLogin() {
        let store = AuthStore(initial: .signedOut)
        let sut = NotFoundViewModelImpl(authStore: store)
        let routes = collect(sut.navigateRoot.asObservable())

        sut.primaryTapped.accept(())

        XCTAssertEqual(routes(), [.login])
    }

    func test_primaryTap_whenSignedIn_routesToHome() {
        let session = AuthSessionFixture.make()
        let store = AuthStore(initial: .signedIn(session))
        let sut = NotFoundViewModelImpl(authStore: store)
        let routes = collect(sut.navigateRoot.asObservable())

        sut.primaryTapped.accept(())

        XCTAssertEqual(routes(), [.home])
    }

    func test_primaryTap_whenUnknown_routesToLogin() {
        let store = AuthStore(initial: .unknown)
        let sut = NotFoundViewModelImpl(authStore: store)
        let routes = collect(sut.navigateRoot.asObservable())

        sut.primaryTapped.accept(())

        XCTAssertEqual(routes(), [.login])
    }
}
