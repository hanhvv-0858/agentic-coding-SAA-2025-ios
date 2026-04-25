import Foundation

enum AppLanguage: String, Codable, CaseIterable, Equatable {
    case vi
    case en

    static let `default`: Self = {
        let preferred = Locale.preferredLanguages.first ?? "en"
        let primary = preferred.split(separator: "-").first.map(String.init) ?? "en"
        return Self(rawValue: primary) ?? .en
    }()
}
