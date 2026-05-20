import SwiftUI

// MARK: - BadgeSpec

/// Metadata for a single pill-shaped badge rendered inside `OverlayHeaderBar`.
struct BadgeSpec {
    let text: String
    let bg: Color
    let textColor: Color

    /// Convenience factory: returns a difficulty badge for the given string,
    /// or `nil` when the difficulty is absent.
    static func difficulty(_ difficulty: String?) -> BadgeSpec? {
        guard let d = difficulty, !d.isEmpty else { return nil }
        let colors = OverlayTheme.badgeColor(for: d)
        return BadgeSpec(text: d.uppercased(), bg: colors.bg, textColor: colors.text)
    }
}
