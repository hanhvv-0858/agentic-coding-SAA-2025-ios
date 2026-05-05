import Foundation

/// Postgres row shape from `public.notifications` (migration 0024).
struct NotificationDTO: Decodable {
    let id: UUID
    let recipientId: UUID
    let type: String
    let payload: AnyJSONCodable?
    let readAt: Date?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case recipientId = "recipient_id"
        case type
        case payload
        case readAt      = "read_at"
        case createdAt   = "created_at"
    }
}

/// Loose JSON wrapper — sibling Notifications spec replaces this with
/// per-type discriminated unions; for US3 we only need to passthrough.
struct AnyJSONCodable: Decodable {
    let asDictionary: [String: AnyHashable]

    init(from decoder: Decoder) throws {
        // US3 PR-M2.4: payload pass-through is intentionally minimal.
        // The full per-type discriminated decoding lives in the sibling
        // Notifications spec; for the Home bell-dot we only count rows.
        self.asDictionary = [:]
    }
}

extension NotificationDTO {
    func toDomain() -> Notification? {
        guard let knownType = NotificationType(rawValue: type) else {
            // Unknown notification_type — sibling spec may add one in
            // a later schema. US3 only counts unread, so we can safely
            // skip rather than fail. Caller (the Realtime stream) just
            // doesn't increment for unknown rows.
            return nil
        }
        return Notification(
            id: id,
            recipientID: recipientId,
            type: knownType,
            payload: payload?.asDictionary ?? [:],
            readAt: readAt,
            createdAt: createdAt
        )
    }
}
