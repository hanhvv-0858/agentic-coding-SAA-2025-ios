import Foundation
import RxSwift

protocol MarkNotificationReadUseCaseProtocol {
    func execute(id: UUID) -> Completable
}

protocol MarkAllNotificationsReadUseCaseProtocol {
    func execute() -> Completable
}

nonisolated final class MarkNotificationReadUseCase: MarkNotificationReadUseCaseProtocol {
    private let repository: NotificationRepository
    init(repository: NotificationRepository) { self.repository = repository }
    func execute(id: UUID) -> Completable { repository.markRead(id: id) }
}

nonisolated final class MarkAllNotificationsReadUseCase: MarkAllNotificationsReadUseCaseProtocol {
    private let repository: NotificationRepository
    init(repository: NotificationRepository) { self.repository = repository }
    func execute() -> Completable { repository.markAllRead() }
}
