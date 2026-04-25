import XCTest
@testable import AIDD_SAA_2025

final class AllowedEmailDomainsTests: XCTestCase {

    func test_allows_matchesExactDomain() {
        let allowlist = AllowedEmailDomains(domains: ["sun-asterisk.com"])
        XCTAssertTrue(allowlist.allows(emailDomain: "sun-asterisk.com"))
    }

    func test_allows_caseInsensitive() {
        let allowlist = AllowedEmailDomains(domains: ["sun-asterisk.com"])
        XCTAssertTrue(allowlist.allows(emailDomain: "Sun-Asterisk.COM"))
    }

    func test_allows_trimsWhitespace() {
        let allowlist = AllowedEmailDomains(domains: ["sun-asterisk.com"])
        XCTAssertTrue(allowlist.allows(emailDomain: "  sun-asterisk.com  "))
    }

    func test_allows_rejectsUnlistedDomain() {
        let allowlist = AllowedEmailDomains(domains: ["sun-asterisk.com"])
        XCTAssertFalse(allowlist.allows(emailDomain: "gmail.com"))
    }

    func test_allowsByEmail_extractsDomain() {
        let allowlist = AllowedEmailDomains(domains: ["sun-asterisk.com"])
        XCTAssertTrue(allowlist.allows(email: "alice@sun-asterisk.com"))
        XCTAssertFalse(allowlist.allows(email: "alice@gmail.com"))
    }

    func test_allowsByEmail_rejectsMalformed() {
        let allowlist = AllowedEmailDomains(domains: ["sun-asterisk.com"])
        XCTAssertFalse(allowlist.allows(email: "no-at-sign"))
        XCTAssertFalse(allowlist.allows(email: ""))
    }
}
