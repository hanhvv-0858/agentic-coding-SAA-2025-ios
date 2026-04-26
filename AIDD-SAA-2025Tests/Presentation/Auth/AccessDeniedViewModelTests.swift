import RxBlocking
import RxCocoa
import RxRelay
import RxSwift
import XCTest
@testable import AIDD_SAA_2025

final class AccessDeniedViewModelTests: XCTestCase {

    private var repository: MockAuthRepository!
    private var disposeBag: DisposeBag!

    override func setUp() {
        super.setUp()
        repository = MockAuthRepository()
        disposeBag = DisposeBag()
    }

    override func tearDown() {
        disposeBag = nil
        repository = nil
        super.tearDown()
    }

    private func makeSUT() -> AccessDeniedViewModelImpl {
        AccessDeniedViewModelImpl(
            signOutUseCase: SignOutUseCase(repository: repository)
        )
    }

    private func collect<T>(_ source: Observable<T>) -> () -> [T] {
        var collected: [T] = []
        source.subscribe(onNext: { collected.append($0) }).disposed(by: disposeBag)
        return { collected }
    }

    func test_primaryTapped_emitsNavigateLogin() {
        let sut = makeSUT()
        let navigations = collect(sut.navigateLogin.asObservable())

        sut.primaryTapped.accept(())

        XCTAssertEqual(navigations().count, 1)
    }

    func test_backTapped_emitsNavigateLogin() {
        let sut = makeSUT()
        let navigations = collect(sut.navigateLogin.asObservable())

        sut.backTapped.accept(())

        XCTAssertEqual(navigations().count, 1)
    }

    func test_bothInputs_mergeOntoSingleSignal() {
        let sut = makeSUT()
        let navigations = collect(sut.navigateLogin.asObservable())

        sut.primaryTapped.accept(())
        sut.backTapped.accept(())

        XCTAssertEqual(navigations().count, 2)
    }

    /// Spec edge case: defensive sign-out on appear if a stale session
    /// somehow leaked through. Verifies the use case is invoked.
    func test_onAppear_triggersDefensiveSignOut() {
        let sut = makeSUT()

        sut.onAppear.accept(())

        XCTAssertEqual(repository.signOutCalls, 1)
    }
}
