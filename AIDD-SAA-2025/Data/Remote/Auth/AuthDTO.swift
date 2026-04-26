import Foundation
import Supabase

/// Maps a `Supabase.Session` (Data SDK type) into the Domain `AuthSession`
/// entity. Lives in the Data layer so Domain stays free of Supabase.
///
/// The Supabase `User.email` is optional — when missing we surface an
/// empty string so `CheckEmailDomainUseCase` (US2) treats the user as
/// disallowed. We deliberately do not log email in this file.
enum AuthDTO {

    static func toDomain(_ session: Supabase.Session) -> AuthSession {
        AuthSession(
            accessToken: session.accessToken,
            refreshToken: session.refreshToken,
            expiresAt: Date(timeIntervalSince1970: session.expiresAt),
            user: AuthUser(
                id: session.user.id,
                email: session.user.email ?? ""
            )
        )
    }
}
