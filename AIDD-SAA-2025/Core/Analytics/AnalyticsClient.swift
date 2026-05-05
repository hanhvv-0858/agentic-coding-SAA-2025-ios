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

    // M2 Home events — per spec TR-007. NO PII allowed: only locale,
    // unread_count_bucket (`0` / `1-5` / `6+`), award.kind, from/to
    // tab IDs, placeholder variant.
    case homeViewed
    case homeAwardCardTapped(kind: String)
    case homeKudosDetailTapped
    case homeBellTapped(unreadBucket: String)
    case homeFabComposeTapped
    case homeFabKudosFeedTapped
    case homeSearchTapped
    case homeLanguageChanged(locale: String)
    case homePullToRefresh
    case homeAboutAwardTapped
    case homeAboutKudosTapped
    case homeTabSwitched(from: String, to: String)
    case homePlaceholderViewed(variant: String)

    var name: String {
        switch self {
        case .loginViewed:                  return "login.viewed"
        case .loginGoogleTapped:            return "login.google_tapped"
        case .loginSuccess:                 return "login.success"
        case .loginDenied:                  return "login.denied"
        case .loginError:                   return "login.error"
        case .homeViewed:                   return "home.viewed"
        case .homeAwardCardTapped:          return "home.award_card_tap"
        case .homeKudosDetailTapped:        return "home.kudos_detail_tap"
        case .homeBellTapped:               return "home.bell_tap"
        case .homeFabComposeTapped:         return "home.fab.compose_tap"
        case .homeFabKudosFeedTapped:       return "home.fab.kudos_feed_tap"
        case .homeSearchTapped:             return "home.search_tap"
        case .homeLanguageChanged:          return "home.language_changed"
        case .homePullToRefresh:            return "home.pull_to_refresh"
        case .homeAboutAwardTapped:         return "home.about_award_tap"
        case .homeAboutKudosTapped:         return "home.about_kudos_tap"
        case .homeTabSwitched:              return "home.tab_switch"
        case .homePlaceholderViewed:        return "home.placeholder.viewed"
        }
    }

    var properties: [String: String] {
        switch self {
        case .loginViewed, .loginGoogleTapped, .loginSuccess,
             .homeViewed, .homeKudosDetailTapped,
             .homeFabComposeTapped, .homeFabKudosFeedTapped,
             .homeSearchTapped, .homePullToRefresh,
             .homeAboutAwardTapped, .homeAboutKudosTapped:
            return [:]
        case .loginDenied(let domain):
            return ["email_domain": domain]
        case .loginError(let code):
            return ["code": code]
        case .homeAwardCardTapped(let kind):
            return ["kind": kind]
        case .homeBellTapped(let bucket):
            return ["unread_count_bucket": bucket]
        case .homeLanguageChanged(let locale):
            return ["locale": locale]
        case .homeTabSwitched(let from, let to):
            return ["from": from, "to": to]
        case .homePlaceholderViewed(let variant):
            return ["variant": variant]
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
