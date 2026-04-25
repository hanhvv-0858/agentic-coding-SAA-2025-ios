import Foundation

struct AllowedEmailDomains: Equatable {
    let domains: Set<String>

    init(domains: Set<String>) {
        self.domains = Set(domains.map { $0.trimmingCharacters(in: .whitespaces).lowercased() })
    }

    func allows(emailDomain: String) -> Bool {
        domains.contains(emailDomain.trimmingCharacters(in: .whitespaces).lowercased())
    }

    func allows(email: String) -> Bool {
        guard let at = email.lastIndex(of: "@") else { return false }
        let domain = email[email.index(after: at)...]
        return allows(emailDomain: String(domain))
    }
}
