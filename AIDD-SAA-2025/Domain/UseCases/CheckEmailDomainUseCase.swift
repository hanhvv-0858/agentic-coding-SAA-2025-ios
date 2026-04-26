import Foundation

protocol CheckEmailDomainUseCaseProtocol {
    func execute(_ session: AuthSession) -> Result<AuthSession, AuthError>
}

/// Pure validation — does NOT mutate state. Caller decides whether to
/// `acceptSession` (allowed) or `signOut` (disallowed).
nonisolated final class CheckEmailDomainUseCase: CheckEmailDomainUseCaseProtocol {

    private let allowlist: AllowedEmailDomains

    init(allowlist: AllowedEmailDomains) {
        self.allowlist = allowlist
    }

    func execute(_ session: AuthSession) -> Result<AuthSession, AuthError> {
        let domain = session.user.emailDomain
        guard !domain.isEmpty, allowlist.allows(emailDomain: domain) else {
            return .failure(.disallowedDomain)
        }
        return .success(session)
    }
}
