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

/// Returns up to 4 teleport spots sorted by distance to the clue's primary
/// coordinate, excluding any disabled teleport IDs. Returns an empty array
/// when the clue has no parseable coordinates.
///
/// When a whole-map walkability grid is available for the clue's map, spots are
/// ranked by actual BFS **walking distance** (which respects rivers, walls and
/// coastlines) rather than straight-line distance. Teleports the player can't
/// walk from — a different island, or off the baked grid — fall back to
/// straight-line distance and sort after every reachable teleport. Without a
/// grid the function degrades to the original straight-line ranking.
func clueClosestTeleports(
    for clue: ClueSolution,
    excluding disabled: Set<String>
) -> [(spot: TeleportSpot, tiles: Double)] {
    guard let (x, y) = parseClueCoords(clue.coordinates) else { return [] }
    let mapId = clue.mapId ?? MapTileCache.defaultMapId
    return walkingClosestTeleports(toGameX: x, gameY: y, mapId: mapId, excluding: disabled)
}

/// Returns up to 4 teleport spots sorted by distance to an arbitrary game-tile
/// point, excluding any disabled teleport IDs. Used by clue overlays (via
/// `clueClosestTeleports`) and by the elite/master compass intersection.
///
/// When a whole-map walkability grid is available for `mapId`, spots are ranked
/// by actual BFS **walking distance** (respecting rivers, walls and coastlines)
/// rather than straight-line distance. Teleports the player can't walk to — a
/// different island, or a point off the baked grid — fall back to straight-line
/// distance and sort after every reachable teleport.
func walkingClosestTeleports(
    toGameX x: Int,
    gameY y: Int,
    mapId: Int,
    excluding disabled: Set<String>
) -> [(spot: TeleportSpot, tiles: Double)] {
    let spots = TeleportCatalogue.shared.spots(forMapId: mapId)
        .filter { !disabled.contains($0.id) }
    let px = Double(x), py = Double(y)

    func straightLine() -> [(spot: TeleportSpot, tiles: Double)] {
        Array(
            spots.map { ($0, hypot(Double($0.x) - px, Double($0.y) - py)) }
                 .sorted { $0.1 < $1.1 }
                 .prefix(4)
        )
    }

    // Teleport / clue landing tiles often classify as obstacles (building
    // floors, decorative tiles), so snap to the nearest walkable tile first.
    let snapRadius = 6
    guard let grid = WalkabilityCache.shared.globalGrid(forMapId: mapId),
          let origin = grid.nearestWalkable(gameX: x, gameY: y, radius: snapRadius),
          let result = WalkabilityCache.shared.walkingDistanceMap(forMapId: mapId,
                                                                  from: origin)
    else {
        return straightLine()
    }
    let dist = result.dist

    let scored: [(spot: TeleportSpot, tiles: Double, reachable: Bool)] =
        spots.map { spot in
            if let t = grid.nearestWalkable(gameX: spot.x, gameY: spot.y,
                                            radius: snapRadius),
               let idx = grid.gridIndex(gameX: t.x, gameY: t.y),
               dist[idx] != Int.max {
                return (spot, Double(dist[idx]), true)
            }
            return (spot, hypot(Double(spot.x) - px, Double(spot.y) - py), false)
        }

    let sorted = scored.sorted { a, b in
        if a.reachable != b.reachable { return a.reachable && !b.reachable }
        return a.tiles < b.tiles
    }
    return Array(sorted.prefix(4).map { (spot: $0.spot, tiles: $0.tiles) })
}
