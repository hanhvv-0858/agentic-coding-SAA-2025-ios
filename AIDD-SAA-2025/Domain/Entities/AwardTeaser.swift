import Foundation

/// Domain entity for an award category as shown on the Home teaser
/// (and the future M4 Award detail screen). Maps from `public.awards`.
struct AwardTeaser: Equatable, Identifiable {
    var id: AwardKind { kind }
    let kind: AwardKind
    let titleVI: String
    let titleEN: String
    let descriptionVI: String
    let descriptionEN: String
    let artworkAssetKey: String
    let displayOrder: Int

    func localisedTitle(for lang: AppLanguage) -> String {
        lang == .vi ? titleVI : titleEN
    }

    func localisedDescription(for lang: AppLanguage) -> String {
        lang == .vi ? descriptionVI : descriptionEN
    }
}

/// State machine for the Awards teaser section on Home (per spec
/// §State Management). Driven by `HomeViewModel.awards: Driver<…>`.
enum AwardsTeaserState: Equatable {
    case loading
    case loaded([AwardTeaser])
    case empty
    case error
}
