import SwiftUI

// MARK: - ItemChipRow

/// Wrapping row of gold-tinted pill chips for emote equipment items.
/// Shows an italic "Nothing equipped" placeholder when `items` is empty.
struct ItemChipRow: View {
    let items: [String]

    var body: some View {
        if items.isEmpty {
            Text("Nothing equipped")
                .font(.system(size: 11).italic())
                .foregroundColor(OverlayTheme.textSecondary.opacity(0.6))
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
        } else {
            ChipFlowLayout(spacing: 4) {
                ForEach(items, id: \.self) { item in
                    Text(item)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(OverlayTheme.gold.opacity(0.9))
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(Capsule().fill(OverlayTheme.gold.opacity(0.12)))
                        .overlay(Capsule().strokeBorder(OverlayTheme.gold.opacity(0.25), lineWidth: 0.5))
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
        }
    }
}

// MARK: - ChipFlowLayout

/// Simple left-to-right wrapping layout for chip rows.
/// Requires macOS 13+ (Layout protocol).
struct ChipFlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 300
        var x: CGFloat = 0, y: CGFloat = 0, rowH: CGFloat = 0
        for sub in subviews {
            let sz = sub.sizeThatFits(.unspecified)
            if x + sz.width > width, x > 0 { y += rowH + spacing; x = 0; rowH = 0 }
            rowH = max(rowH, sz.height)
            x += sz.width + spacing
        }
        return CGSize(width: width, height: y + rowH)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX, y = bounds.minY, rowH: CGFloat = 0
        for sub in subviews {
            let sz = sub.sizeThatFits(.unspecified)
            if x + sz.width > bounds.maxX, x > bounds.minX {
                y += rowH + spacing; x = bounds.minX; rowH = 0
            }
            sub.place(at: CGPoint(x: x, y: y), proposal: .unspecified)
            rowH = max(rowH, sz.height)
            x += sz.width + spacing
        }
    }
}
