import SwiftUI

// MARK: - EmoteStepList

/// Numbered list of emote perform steps. Each element of `steps` is a list of
/// alternative emote names for that step, joined with " or " inline.
/// Uses "PERFORM IN ORDER" as the section label when there are multiple steps.
struct EmoteStepList: View {
    let steps: [[String]]

    private var sectionLabel: String { steps.count > 1 ? "PERFORM IN ORDER" : "PERFORM" }

    var body: some View {
        if !steps.isEmpty {
            VStack(alignment: .leading, spacing: 4) {
                Text(sectionLabel)
                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                    .foregroundColor(OverlayTheme.textSecondary.opacity(0.7))
                    .padding(.horizontal, 12)

                ForEach(Array(steps.enumerated()), id: \.offset) { idx, alts in
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text("\(idx + 1).")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(OverlayTheme.textSecondary.opacity(0.5))
                            .frame(width: 16, alignment: .trailing)
                        Text(alts.joined(separator: " or "))
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(OverlayTheme.textPrimary)
                    }
                    .padding(.horizontal, 12)
                }
            }
            .padding(.vertical, 6)
        }
    }
}
