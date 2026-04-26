import Foundation

enum AuthError: Error, Equatable {
    case cancelled
    case network
    case disallowedDomain
    case serviceUnavailable
    case unknown(String)

    static func == (lhs: AuthError, rhs: AuthError) -> Bool {
        switch (lhs, rhs) {
        case (.cancelled, .cancelled),
             (.network, .network),
             (.disallowedDomain, .disallowedDomain),
             (.serviceUnavailable, .serviceUnavailable):
            return true
        case (.unknown(let l), .unknown(let r)):
            return l == r
        default:
            return false
        }
    }
}

extension AuthError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .cancelled:
            return nil
        case .network:
            return String(localized: "auth.error.network")
        case .disallowedDomain:
            return String(localized: "auth.error.disallowedDomain")
        case .serviceUnavailable:
            return String(localized: "auth.error.network")
        case .unknown:
            return String(localized: "auth.error.network")
        }
    }
}
