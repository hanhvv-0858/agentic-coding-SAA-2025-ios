import Foundation
import os

/// Thin pluggable analytics surface. The real backend (Mixpanel,
/// Segment, etc.) is wired in M2+ — for M1 we use `OSLogAnalyticsClient`
/// which writes to OSLog.
///
/// **Constitution V (no PII)**: never pass `email`, `user_id`, tokens,
/// or any other identifier through `properties`. Domain (`email_domain`)
/// and error codes are explicitly allowed by spec §Analytics.
nonisolated protocol AnalyticsClient: AnyObject, Sendable {
    func track(_ event: AnalyticsEvent)
}

enum AnalyticsEvent {
    case loginViewed
    case loginGoogleTapped
    case loginSuccess
    case loginDenied(emailDomain: String)
    case loginError(code: String)

    var name: String {
        switch self {
        case .loginViewed:        return "login.viewed"
        case .loginGoogleTapped:  return "login.google_tapped"
        case .loginSuccess:       return "login.success"
        case .loginDenied:        return "login.denied"
        case .loginError:         return "login.error"
        }
    }

    var properties: [String: String] {
        switch self {
        case .loginViewed, .loginGoogleTapped, .loginSuccess:
            return [:]
        case .loginDenied(let domain):
            return ["email_domain": domain]
        case .loginError(let code):
            return ["code": code]
        }
    }
}

/// Default M1 client — OSLog only. Replace with a real SDK in M2.
nonisolated final class OSLogAnalyticsClient: AnalyticsClient, @unchecked Sendable {

    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "com.sun-asterisk.aidd-saa-2025",
        category: "analytics"
    )

    func track(_ event: AnalyticsEvent) {
        // Properties are joined as `key=value` pairs using `.public`
        // interpolation — every value is constrained by `AnalyticsEvent`
        // to be non-PII (spec §Analytics).
        let propsString = event.properties
            .sorted(by: { $0.key < $1.key })
            .map { "\($0.key)=\($0.value)" }
            .joined(separator: " ")
        if propsString.isEmpty {
            logger.info("\(event.name, privacy: .public)")
        } else {
            logger.info("\(event.name, privacy: .public) \(propsString, privacy: .public)")
        }
    }
}
