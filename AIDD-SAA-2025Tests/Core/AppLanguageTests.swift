import XCTest
@testable import AIDD_SAA_2025

final class AppLanguageTests: XCTestCase {

    func test_rawValues_areLowercase() {
        XCTAssertEqual(AppLanguage.vi.rawValue, "vi")
        XCTAssertEqual(AppLanguage.en.rawValue, "en")
    }

    func test_caseIterable_listsBothLanguages() {
        XCTAssertEqual(Set(AppLanguage.allCases), [.vi, .en])
    }
}
