import RxBlocking
import RxRelay
import RxSwift
import XCTest
@testable import AIDD_SAA_2025

final class MarkNotificationReadUseCaseTests: XCTestCase {

    private final class StubRepository: NotificationRepository {
        var markReadResult: Completable = .empty()
        var markAllReadResult: Completable = .empty()
        var markReadIds: [UUID] = []
        var markAllReadCalls = 0

        func unreadCount() -> Single<Int> { .just(0) }
        func observeUnreadCount() -> Observable<Int> { .empty() }
        func markRead(id: UUID) -> Completable {
            markReadIds.append(id)
            return markReadResult
        }
        func markAllRead() -> Completable {
            markAllReadCalls += 1
            return markAllReadResult
        }
    }

    func test_markRead_executesOnRepository() throws {
        let repo = StubRepository()
        let id = UUID()
        let sut = MarkNotificationReadUseCase(repository: repo)

        let result = sut.execute(id: id).toBlocking().materialize()
        if case .failed(_, let err) = result { XCTFail("\(err)"); return }

        XCTAssertEqual(repo.markReadIds, [id])
    }

    func test_markRead_propagatesErrors() {
        struct BoomError: Error {}
        let repo = StubRepository()
        repo.markReadResult = .error(BoomError())
        let sut = MarkNotificationReadUseCase(repository: repo)

        let result = sut.execute(id: UUID()).toBlocking().materialize()
        guard case .failed = result else {
            XCTFail("Expected failed completion"); return
        }
    }

    func test_markAllRead_executesOnRepository() throws {
        let repo = StubRepository()
        let sut = MarkAllNotificationsReadUseCase(repository: repo)

        let result = sut.execute().toBlocking().materialize()
        if case .failed(_, let err) = result { XCTFail("\(err)"); return }

        XCTAssertEqual(repo.markAllReadCalls, 1)
    }
}
