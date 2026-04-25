import Foundation

struct AppConfig: Equatable {
    let supabaseURL: URL
    let supabaseAnonKey: String
    let allowedEmailDomains: Set<String>
    let oauthRedirectURL: URL
    let eventTargetDate: Date
    let eventPlace: String
    let liveStreamURL: URL?
}

extension AppConfig {
    static func load(bundle: Bundle = .main) throws -> Self {
        let info = bundle.infoDictionary ?? [:]

        guard
            let urlString = info["SUPABASE_URL"] as? String,
            let url = URL(string: urlString.replacingOccurrences(of: "/$()", with: ""))
        else { throw ConfigError.missing("SUPABASE_URL") }

        guard
            let anonKey = info["SUPABASE_ANON_KEY"] as? String,
            anonKey != "REPLACE_ME"
        else { throw ConfigError.missing("SUPABASE_ANON_KEY") }

        guard let domainsString = info["ALLOWED_EMAIL_DOMAINS"] as? String else {
            throw ConfigError.missing("ALLOWED_EMAIL_DOMAINS")
        }

        let domains = Set(
            domainsString
                .split(separator: " ")
                .map { $0.trimmingCharacters(in: .whitespaces).lowercased() }
                .filter { !$0.isEmpty }
        )
        guard !domains.isEmpty else { throw ConfigError.missing("ALLOWED_EMAIL_DOMAINS (empty)") }

        guard
            let redirectString = info["OAUTH_REDIRECT_URL"] as? String,
            let redirectURL = URL(string: redirectString.replacingOccurrences(of: "/$()", with: ""))
        else { throw ConfigError.missing("OAUTH_REDIRECT_URL") }

        guard
            let dateString = info["EVENT_TARGET_DATE"] as? String,
            let targetDate = ISO8601DateFormatter().date(from: dateString)
        else { throw ConfigError.missing("EVENT_TARGET_DATE") }

        let place = (info["EVENT_PLACE"] as? String) ?? ""
        let liveStream = (info["LIVE_STREAM_URL"] as? String)
            .flatMap { URL(string: $0.replacingOccurrences(of: "/$()", with: "")) }

        return Self(
            supabaseURL: url,
            supabaseAnonKey: anonKey,
            allowedEmailDomains: domains,
            oauthRedirectURL: redirectURL,
            eventTargetDate: targetDate,
            eventPlace: place,
            liveStreamURL: liveStream
        )
    }
}

enum ConfigError: Error, CustomStringConvertible {
    case missing(String)

    var description: String {
        switch self {
        case .missing(let key): return "AppConfig: missing or invalid Info.plist key '\(key)'"
        }
    }
}
