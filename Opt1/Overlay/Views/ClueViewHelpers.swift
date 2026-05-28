import Foundation
import Opt1Matching

// MARK: - Shared utilities for clue overlay views

/// Parses the first game-tile coordinate pair from a `ClueSolution.coordinates` string.
/// Handles both single points ("3213,3424") and semicolon-separated polygon rings.
func parseClueCoords(_ str: String?) -> (x: Int, y: Int)? {
    guard let str else { return nil }
    let parts = str.split(separator: ";").flatMap {
        $0.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) }
    }
    guard parts.count >= 2, let x = Int(parts[0]), let y = Int(parts[1]) else { return nil }
    return (x, y)
}

/// Returns up to 4 teleport spots sorted by tile distance to the clue's
/// primary coordinate, excluding any disabled teleport IDs.
/// Returns an empty array when the clue has no parseable coordinates.
func clueClosestTeleports(
    for clue: ClueSolution,
    excluding disabled: Set<String>
) -> [(spot: TeleportSpot, tiles: Double)] {
    guard let (x, y) = parseClueCoords(clue.coordinates) else { return [] }
    let px = Double(x), py = Double(y)
    return Array(
        TeleportCatalogue.shared.spots(forMapId: clue.mapId ?? MapTileCache.defaultMapId)
            .filter { !disabled.contains($0.id) }
            .map { ($0, hypot(Double($0.x) - px, Double($0.y) - py)) }
            .sorted { $0.1 < $1.1 }
            .prefix(4)
    )
}
