import Foundation

/// The 6 canonical SAA 2025 award categories.
/// Raw values match the `award_kind` Postgres enum in
/// `.momorph/contexts/migrations/0025_awards_catalogue.sql` — DB schema
/// is the source of truth for the kind set.
enum AwardKind: String, CaseIterable, Codable, Hashable {
    case mvp                = "mvp"
    case bestManager        = "best_manager"
    case signatureCreator   = "signature_creator"
    case topProject         = "top_project"
    case topProjectLeader   = "top_project_leader"
    case topTalent          = "top_talent"
}
