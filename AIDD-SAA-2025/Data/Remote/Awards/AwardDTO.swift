import Foundation

/// Postgres row shape from `public.awards` (migration 0025). Snake-case
/// column names are mapped via `CodingKeys`.
struct AwardDTO: Decodable, Equatable {
    let kind: String
    let titleVi: String
    let titleEn: String
    let descriptionVi: String
    let descriptionEn: String
    let artworkAssetKey: String
    let displayOrder: Int

    enum CodingKeys: String, CodingKey {
        case kind
        case titleVi          = "title_vi"
        case titleEn          = "title_en"
        case descriptionVi    = "description_vi"
        case descriptionEn    = "description_en"
        case artworkAssetKey  = "artwork_asset_key"
        case displayOrder     = "display_order"
    }
}

extension AwardDTO {
    /// Domain mapping. Validates the `kind` string against
    /// `AwardKind.allCases` and surfaces `AwardError.unknownKind` if the
    /// backend ships a 7th category without a matching Swift case
    /// (per plan §Architecture validation).
    func toDomain() throws -> AwardTeaser {
        guard let knownKind = AwardKind(rawValue: kind) else {
            throw AwardError.unknownKind(kind)
        }
        return AwardTeaser(
            kind: knownKind,
            titleVI: titleVi,
            titleEN: titleEn,
            descriptionVI: descriptionVi,
            descriptionEN: descriptionEn,
            artworkAssetKey: artworkAssetKey,
            displayOrder: displayOrder
        )
    }
}
