import Foundation

/// All 7 typed notification rows defined in migration 0024.
/// `recipient_id = auth.uid()` is enforced at RLS level — the iOS
/// client never sees foreign rows.
enum NotificationType: String, Codable, CaseIterable, Hashable {
    case kudosReceived       = "kudos_received"
    case kudosLiked          = "kudos_liked"
    case secretBoxGranted    = "secret_box_granted"
    case levelUp             = "level_up"
    case contentSoftHidden   = "content_soft_hidden"
    case badgeCollected      = "badge_collected"
    case adminReviewRequest  = "admin_review_request"
}

/// Domain notification row from `public.notifications`. The full
/// taxonomy + `payload` parsing lives in the sibling Notifications
/// spec; for US3 (Home bell-dot) we only need `id` (mark-read targets)
/// and `readAt` (defensive filter for Realtime events).
///
/// Per Constitution V — when logging this entity, NEVER interpolate
/// `recipientID` or `payload`. Only `id` and `type.rawValue` are
/// safe to log.
struct Notification: Equatable, Identifiable, Hashable {
    let id: UUID
    let recipientID: UUID
    let type: NotificationType
    let payload: [String: AnyHashable]
    let readAt: Date?
    let createdAt: Date

    static func == (lhs: Notification, rhs: Notification) -> Bool {
        lhs.id == rhs.id
            && lhs.recipientID == rhs.recipientID
            && lhs.type == rhs.type
            && lhs.readAt == rhs.readAt
            && lhs.createdAt == rhs.createdAt
            && NSDictionary(dictionary: lhs.payload).isEqual(to: rhs.payload)
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    var isUnread: Bool { readAt == nil }
}
