import SwiftUI
import Opt1Matching

// MARK: - WorldMapSection

/// Renders an `RSWorldMapView` centred on the clue's coordinates, or a hatched
/// placeholder when no tile cache exists for that region. Silently omits itself
/// when `clue.coordinates` is nil.
struct WorldMapSection: View {
    let clue: ClueSolution
    var extraPins: [(x: Int, y: Int)] = []
    var hideyHolePins: [(x: Int, y: Int)] = []
    var viewportHeight: CGFloat = 155
    /// Propagated up to the parent so it can conditionally suppress features
    /// (e.g. closest-teleport) that are unreliable when no surface tiles exist.
    @Binding var hasTiles: Bool?

    private var coords: (Int, Int)? { parseGameCoords(clue.coordinates) }

    var body: some View {
        if let (x, y) = coords {
            if hasTiles == false {
                hatchedPlaceholder
            } else {
                RSWorldMapView(
                    gameX: x,
                    gameY: y,
                    mapId: clue.mapId ?? MapTileCache.defaultMapId,
                    extraPins: extraPins,
                    viewportHeight: viewportHeight,
                    hasTiles: $hasTiles,
                    hideyHolePins: hideyHolePins
                )
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
            }
        }
    }

    private var hatchedPlaceholder: some View {
        ZStack {
            Canvas { ctx, size in
                let spacing: CGFloat = 10
                var path = Path()
                var x: CGFloat = -size.height
                while x < size.width + size.height {
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x + size.height, y: size.height))
                    x += spacing
                }
                ctx.stroke(path, with: .color(OverlayTheme.textSecondary.opacity(0.15)), lineWidth: 1)
            }
            .frame(maxWidth: .infinity)
            .frame(height: viewportHeight)

            Text("No map tiles for this region")
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(OverlayTheme.textSecondary.opacity(0.5))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
    }

    private func parseGameCoords(_ str: String?) -> (Int, Int)? {
        guard let str else { return nil }
        let parts = str.split(separator: ";").flatMap {
            $0.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) }
        }
        guard parts.count >= 2,
              let x = Int(parts[0]),
              let y = Int(parts[1]) else { return nil }
        return (x, y)
    }
}
