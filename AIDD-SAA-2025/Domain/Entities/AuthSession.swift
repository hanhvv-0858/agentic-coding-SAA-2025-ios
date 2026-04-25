import Foundation

struct AuthSession: Equatable {
    let accessToken: String
    let refreshToken: String
    let expiresAt: Date
    let user: AuthUser

    var isExpired: Bool { expiresAt <= Date() }
}

struct AuthUser: Equatable {
    let id: UUID
    let email: String

    var emailDomain: String {
        guard let at = email.lastIndex(of: "@") else { return "" }
        return String(email[email.index(after: at)...])
    }
}
