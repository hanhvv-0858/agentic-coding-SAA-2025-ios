import Foundation

enum AppRoute: Hashable {
    case login
    case accessDenied
    case notFound(source: NotFoundSource)
    case home
    case notifications
    case profileMe(anchor: ProfileAnchor?)
    case profileOther(userId: UUID)
    case awardDetail(kind: String)
    case sunKudos
    case allKudos
    case writeKudo(recipientId: UUID?)
    case viewKudo(kudoId: UUID)
    case searchSunner
    case secretBox
    case theLe
    case communityStandards
}

enum NotFoundSource: String, Hashable {
    case deeplink
    case notification
    case internalNav
}

enum ProfileAnchor: String, Hashable {
    case level
    case badges
}
