import SwiftUI

// MARK: - OverlayHeaderBar

/// Unified header bar shared by all clue overlay panels.
/// Shows the clue-type badge, optional difficulty/extra badges, a spacer,
/// and a circular X close button.
struct OverlayHeaderBar: View {
    let type: String
    var badges: [BadgeSpec] = []
    var onClose: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 8) {
            Text(type)
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundColor(.black.opacity(0.6))
                .padding(.horizontal, 6).padding(.vertical, 2)
                .background(Capsule().fill(OverlayTheme.gold.opacity(0.85)))

            ForEach(Array(badges.enumerated()), id: \.offset) { _, badge in
                Text(badge.text)
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundColor(badge.textColor)
                    .padding(.horizontal, 6).padding(.vertical, 2)
                    .background(Capsule().fill(badge.bg))
            }

            Spacer()

            if let onClose {
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(OverlayTheme.gold.opacity(0.8))
                        .frame(width: 18, height: 18)
                        .background(Circle().fill(OverlayTheme.gold.opacity(0.12)))
                        .overlay(Circle().strokeBorder(OverlayTheme.gold.opacity(0.25), lineWidth: 0.5))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Close overlay")
            }
        }
        .padding(.horizontal, 12).padding(.top, 10).padding(.bottom, 6)
    }
}
