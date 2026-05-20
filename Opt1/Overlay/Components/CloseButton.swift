import SwiftUI

// MARK: - CloseButton

/// Gold-filled full-width close button, shown at the bottom of every clue overlay panel.
struct CloseButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text("Close")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(OverlayTheme.bgDeep)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                .background(RoundedRectangle(cornerRadius: 6).fill(OverlayTheme.gold.opacity(0.75)))
                .overlay(RoundedRectangle(cornerRadius: 6)
                    .strokeBorder(OverlayTheme.goldBorder.opacity(0.4), lineWidth: 0.5))
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 12)
        .padding(.bottom, 10)
    }
}
