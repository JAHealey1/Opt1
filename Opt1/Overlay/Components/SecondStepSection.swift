import SwiftUI

// MARK: - SecondStepSection

/// Renders a "SECOND STEP" block for clues whose NPC gives a puzzle box or
/// other follow-up step after the player speaks to them.
///
/// Used by both `AnagramClueView` and `CrypticClueView` — any clue type can
/// have a `secondStep` value when the NPC issues a puzzle rather than a
/// challenge scroll.
struct SecondStepSection: View {
    let step: String

    /// Puzzle keys that Opt1 cannot auto-solve.
    /// Keep in sync with `DetectionQualityGate.unsupportedPuzzleKeys`.
    private static let unsupportedPuzzleKeys: Set<String> = ["tree", "bridge", "castle", "troll"]

    private var puzzleKey: String? {
        step.firstMatch(of: /\(([^)]+)\)/).map { String($0.output.1).lowercased() }
    }
    private var isSlidePuzzle: Bool { step.lowercased().contains("puzzle box") }
    private var isUnsupported: Bool {
        isSlidePuzzle && puzzleKey.map { Self.unsupportedPuzzleKeys.contains($0) } == true
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("SECOND STEP")
                .font(.system(size: 8, weight: .bold, design: .monospaced))
                .foregroundColor(OverlayTheme.textSecondary.opacity(0.7))

            HStack(alignment: .top, spacing: 6) {
                Image(systemName: isSlidePuzzle ? "puzzlepiece.fill" : "puzzlepiece")
                    .font(.system(size: 11))
                    .foregroundColor(OverlayTheme.textSecondary)
                    .padding(.top, 1)
                Text(step)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(OverlayTheme.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if isUnsupported {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 9))
                        .foregroundColor(OverlayTheme.gold.opacity(0.7))
                    Text("Not currently supported by Opt1")
                        .font(.system(size: 10).italic())
                        .foregroundColor(OverlayTheme.textSecondary.opacity(0.6))
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
