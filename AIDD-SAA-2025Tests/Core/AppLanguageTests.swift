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

    // MARK: - resolveDefault (US3 AS3)

    func test_resolveDefault_viPrimary_returnsVi() {
        XCTAssertEqual(AppLanguage.resolveDefault(from: ["vi-VN", "en"]), .vi)
    }

    func test_resolveDefault_enPrimary_returnsEn() {
        XCTAssertEqual(AppLanguage.resolveDefault(from: ["en-US"]), .en)
    }

    func test_resolveDefault_unsupportedPrimary_fallsBackToEn() {
        XCTAssertEqual(AppLanguage.resolveDefault(from: ["fr-FR", "es"]), .en)
    }

    func test_resolveDefault_emptyList_fallsBackToEn() {
        XCTAssertEqual(AppLanguage.resolveDefault(from: []), .en)
    }

    func test_resolveDefault_bareLanguageCode_works() {
        XCTAssertEqual(AppLanguage.resolveDefault(from: ["vi"]), .vi)
    }
}
