import RxBlocking
import RxSwift
import XCTest
@testable import AIDD_SAA_2025

final class ObserveSessionUseCaseTests: XCTestCase {

    private var repository: MockAuthRepository!
    private var sut: ObserveSessionUseCase!

    override func setUp() {
        super.setUp()
        repository = MockAuthRepository()
        sut = ObserveSessionUseCase(repository: repository)
    }

    override func tearDown() {
        sut = nil
        repository = nil
        super.tearDown()
    }

    func test_execute_emitsSequenceFromRepository() throws {
        let session = AuthSessionFixture.make()
        repository.observeStream = Observable.from([
            AuthState.signedOut,
            .signedIn(session),
            .signedOut
        ])

        let received = try sut.execute().toBlocking(timeout: 1).toArray()

        XCTAssertEqual(received, [.signedOut, .signedIn(session), .signedOut])
        XCTAssertEqual(repository.observeCalls, 1)
    }

    func test_execute_emptyStream_completesWithoutItems() throws {
        repository.observeStream = .empty()

        let received = try sut.execute().toBlocking(timeout: 1).toArray()

        XCTAssertTrue(received.isEmpty)
    }
}
