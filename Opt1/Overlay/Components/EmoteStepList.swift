import SwiftUI

// MARK: - EmoteStepList

/// Numbered list of emote perform steps. Each element of `steps` is a list of
/// alternative emote names for that step, joined with " or " inline.
/// The section header ("PERFORM" / "PERFORM IN ORDER") is the caller's responsibility.
struct EmoteStepList: View {
    let steps: [[String]]

    var body: some View {
        if !steps.isEmpty {
            VStack(alignment: .leading, spacing: 4) {
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
                }
            }
        }
    }
}
