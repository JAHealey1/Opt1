import SwiftUI

// MARK: - TravelRow

/// Displays the first travel suggestion from the wiki-scraped `clue.travel` field.
///
/// The full travel string may contain multiple bullet-separated options joined
/// with ` • `. This component surfaces only the first — typically the fastest
/// route — above `ClosestTeleportBanner` so the user sees both the wiki's
/// recommended path and the catalogue's closest teleport in one glance.
struct TravelRow: View {
    let travel: String

    /// First bullet item, or the full string when no bullet separator exists.
    private var primaryOption: String {
        (travel.components(separatedBy: " • ").first ?? travel)
            .trimmingCharacters(in: .whitespaces)
    }

    var body: some View {
        if !primaryOption.isEmpty {
            VStack(alignment: .leading, spacing: 3) {
                Text("TRAVEL")
                    .font(.system(size: 8, weight: .semibold, design: .monospaced))
                    .foregroundColor(OverlayTheme.textSecondary.opacity(0.55))
                Text(primaryOption)
                    .font(.system(size: 11))
                    .foregroundColor(OverlayTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
