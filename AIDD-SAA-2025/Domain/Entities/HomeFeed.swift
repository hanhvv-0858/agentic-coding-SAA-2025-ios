import Foundation

/// Aggregate returned by `FetchHomeFeedUseCase` — combines the three
/// "on screen load" queries (awards teaser, kudos banner, initial
/// unread count) into a single value. Per-section partial-failure
/// is captured via the wrapped optionals: `kudosBanner == nil` means
/// the banner failed/empty (fallback rendered by View), and `awards`
/// being empty means the section shows the empty-state copy.
///
/// Errors that affect the entire feed (e.g. session vanished) bubble
/// up via the `Single<HomeFeed>` error channel; per-section errors
/// are absorbed inside the use case and reported via `awards` /
/// `kudosBanner` shape.
struct HomeFeed: Equatable {
    let awards: [AwardTeaser]
    let kudosBanner: KudosHighlight?
    let unreadNotificationCount: Int
}
