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

    /// Substring after the *last* `@`, trimmed of surrounding whitespace,
    /// NFC-normalised, lowercased. Returns "" if no `@` is present or the
    /// `@` is the last character. Used by `CheckEmailDomainUseCase`; never
    /// log alongside other PII.
    var emailDomain: String {
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let at = trimmed.lastIndex(of: "@") else { return "" }
        let after = trimmed.index(after: at)
        guard after < trimmed.endIndex else { return "" }
        return String(trimmed[after...]).precomposedStringWithCanonicalMapping.lowercased()
    }
}
