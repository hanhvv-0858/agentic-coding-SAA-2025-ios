import Foundation

enum AppLanguage: String, Codable, CaseIterable, Equatable {
    case vi
    case en

    /// Spec US3 AS3: default to the device locale if it is `vi` or `en`,
    /// otherwise fall back to `en`. Pure function for testability.
    static func resolveDefault(from preferredLanguages: [String]) -> AppLanguage {
        let primary = preferredLanguages.first?.split(separator: "-").first.map(String.init) ?? "en"
        return AppLanguage(rawValue: primary) ?? .en
    }

    static let `default`: Self = resolveDefault(from: Locale.preferredLanguages)
}
