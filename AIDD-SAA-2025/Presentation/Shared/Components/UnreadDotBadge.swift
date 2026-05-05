import SwiftUI

/// Atom: a small unread-marker dot rendered next to a parent control
/// (bell, avatar, list row). Pure presentation — visibility is driven
/// by the `hasUnread` Bool passed in.
///
/// Color resolved at T103b from Figma node `I6885:9057;88:1830;72:1627`
/// (mm_media_Badge/Dot): `#D4271D` (rgba 212, 39, 29). Replaces the
/// PR-M2.2-part-1 placeholder `Color.red` (#FF3B30) — see
/// design-style.md §6 deviation #7 (closed).
struct UnreadDotBadge: View {

    static let dotColor = Color(red: 212/255, green: 39/255, blue: 29/255)

    let hasUnread: Bool
    var diameter: CGFloat = 8

    var body: some View {
        Circle()
            .fill(Self.dotColor)
            .frame(width: diameter, height: diameter)
            .opacity(hasUnread ? 1 : 0)
            .accessibilityHidden(true)
            .animation(.easeInOut(duration: 0.18), value: hasUnread)
    }
}
