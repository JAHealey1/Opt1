import Foundation

// MARK: - Walkability Grid

/// A compact walkability mask for a single scan-clue region at game-tile
/// resolution. Loaded from `walkability.json` and cached for the app's lifetime.
///
/// Bits are packed 8-per-byte; index = row × width + col where row=0 is
/// the south edge (lowest game-y) and col=0 is the west edge (lowest game-x).
/// A bit value of 1 means the tile is walkable.
///
/// Tiles outside the grid's bounds are assumed walkable so the optimiser can
/// gracefully handle candidates that stray outside the stored area.
struct WalkabilityGrid {
    let regionId:  String
    let mapId:     Int
    /// Game-tile X of the grid's west edge (column 0).
    let originX:   Int
    /// Game-tile Y of the grid's south edge (row 0).
    let originY:   Int
    let width:     Int
    let height:    Int
    /// Packed bit array. Internal but non-private so `WalkabilityCache` can
    /// construct instances directly without a cross-module initialiser.
    let bits:      [UInt8]

    // MARK: - Queries

    func isWalkable(gameX: Int, gameY: Int) -> Bool {
        let col = gameX - originX
        let row = gameY - originY
        guard col >= 0, col < width, row >= 0, row < height else { return true }
        let idx = row * width + col
        return (bits[idx >> 3] >> (idx & 7)) & 1 == 1
    }

    /// Returns the packed-array index for a game coordinate, or nil when
    /// the position is outside the grid. Used by `BFSPathfinder` to look up
    /// pre-computed distances without an extra bounds check.
    func gridIndex(gameX: Int, gameY: Int) -> Int? {
        let col = gameX - originX
        let row = gameY - originY
        guard col >= 0, col < width, row >= 0, row < height else { return nil }
        return row * width + col
    }

    /// True when the grid fully covers the supplied bounding box, meaning BFS
    /// distances will be accurate everywhere the optimiser might place candidates.
    func covers(xMin: Int, yMin: Int, xMax: Int, yMax: Int) -> Bool {
        xMin >= originX && yMin >= originY
            && xMax < originX + width && yMax < originY + height
    }

    /// Returns the closest walkable tile to `(gameX, gameY)` within `radius`
    /// game tiles (Chebyshev), or `nil` when none is found.
    ///
    /// Teleport destinations and clue dig spots frequently land on a tile the
    /// pixel classifier marks as an obstacle (a building floor, a decorative
    /// tile, the exact pixel of a wall). Snapping to the nearest walkable tile
    /// before running BFS avoids spurious "unreachable" results.
    func nearestWalkable(gameX: Int, gameY: Int, radius: Int) -> (x: Int, y: Int)? {
        if isWalkableWithinBounds(gameX: gameX, gameY: gameY) {
            return (gameX, gameY)
        }
        for r in 1 ... max(1, radius) {
            for dy in -r ... r {
                for dx in -r ... r {
                    // Only the ring at Chebyshev distance r (skip the interior
                    // already tested at smaller radii).
                    guard abs(dx) == r || abs(dy) == r else { continue }
                    let x = gameX + dx
                    let y = gameY + dy
                    if isWalkableWithinBounds(gameX: x, gameY: y) {
                        return (x, y)
                    }
                }
            }
        }
        return nil
    }

    /// Like `isWalkable`, but tiles outside the grid bounds are NOT assumed
    /// walkable. Used by whole-map distance queries where off-grid means sea.
    private func isWalkableWithinBounds(gameX: Int, gameY: Int) -> Bool {
        let col = gameX - originX
        let row = gameY - originY
        guard col >= 0, col < width, row >= 0, row < height else { return false }
        let idx = row * width + col
        return (bits[idx >> 3] >> (idx & 7)) & 1 == 1
    }
}

// MARK: - JSON Backing (private)

private struct WalkabilityGridData: Codable {
    let regionId:  String
    let mapId:     Int
    let originX:   Int
    let originY:   Int
    let width:     Int
    let height:    Int
    /// Base64-encoded packed bit array (1 bit per tile, row-major, LSB first).
    let walkable:  String
    /// Tiles that are forced walkable regardless of the pixel classification,
    /// e.g. agility shortcuts embedded in otherwise impassable walls.
    let shortcuts: [ShortcutTile]?

    struct ShortcutTile: Codable {
        let x: Int
        let y: Int
        let name: String?
    }
}

// MARK: - Walkability Cache

/// Singleton that loads and caches walkability grids from the bundled
/// `walkability.json`. Returns `nil` for any region whose grid has not yet
/// been baked — the caller should fall back to Chebyshev distance.
///
/// The file is absent from the bundle until `build_walkability.py` has been
/// run for at least one scan region; silence on missing file is intentional.
///
/// `load()` is written once (guarded by `loaded`) and is always called at app
/// startup before any concurrent reads, so `nonisolated(unsafe)` is safe here.
final class WalkabilityCache: @unchecked Sendable {

    static let shared = WalkabilityCache()
    nonisolated(unsafe) private var grids:  [WalkabilityGrid] = []
    /// Whole-map grids (one per map) from `walkability_global.json`. Kept
    /// separate from `grids` so `grid(forMapId:covers:)` continues to return
    /// the precise per-region grids used by `ScanOptimiser` — a coarse global
    /// grid trivially "covers" any box and would otherwise win that lookup.
    nonisolated(unsafe) private var globalGrids: [WalkabilityGrid] = []
    nonisolated(unsafe) private var loaded = false

    /// Single-clue memo for whole-map BFS distance maps. The closest-teleport
    /// UI recomputes for the same clue tile across re-renders, so caching the
    /// most recent few origins keeps it free. Keyed by (mapId, originX, originY).
    nonisolated(unsafe) private var distanceCache:
        [(mapId: Int, x: Int, y: Int, dist: [Int])] = []
    private let distanceCacheCapacity = 4

    private init() {}

    /// Loads `walkability.json` and `walkability_global.json` from the app
    /// bundle. Safe to call repeatedly; subsequent calls are idempotent.
    func load() {
        guard !loaded else { return }
        loaded = true
        grids       = Self.loadGrids(resource: "walkability")
        globalGrids = Self.loadGrids(resource: "walkability_global")
        if !grids.isEmpty || !globalGrids.isEmpty {
            print("[Opt1] Loaded \(grids.count) walkability grid(s), "
                  + "\(globalGrids.count) whole-map grid(s)")
        }
    }

    /// Decodes a `[WalkabilityGridData]` JSON resource into grids, forcing any
    /// declared shortcut tiles walkable. Returns an empty array when the
    /// resource is absent (expected until the build script has produced it).
    private static func loadGrids(resource: String) -> [WalkabilityGrid] {
        guard let url = Bundle.main.url(forResource: resource,
                                        withExtension: "json") else {
            return []
        }
        do {
            let data    = try Data(contentsOf: url)
            let decoded = try JSONDecoder().decode([WalkabilityGridData].self,
                                                   from: data)
            return decoded.compactMap { d -> WalkabilityGrid? in
                guard let raw = Data(base64Encoded: d.walkable) else {
                    print("[Opt1] WalkabilityCache: invalid base64 for \(d.regionId)")
                    return nil
                }
                var bits = [UInt8](raw)
                for s in d.shortcuts ?? [] {
                    let col = s.x - d.originX
                    let row = s.y - d.originY
                    guard col >= 0, col < d.width,
                          row >= 0, row < d.height else { continue }
                    let idx = row * d.width + col
                    bits[idx >> 3] |= 1 << (idx & 7)
                }
                return WalkabilityGrid(regionId: d.regionId,
                                       mapId:    d.mapId,
                                       originX:  d.originX,
                                       originY:  d.originY,
                                       width:    d.width,
                                       height:   d.height,
                                       bits:     bits)
            }
        } catch {
            print("[Opt1] Failed to load \(resource).json: \(error)")
            return []
        }
    }

    /// Returns the first grid for `mapId` that fully covers the given bounding
    /// box, or `nil` if none has been baked yet.
    func grid(forMapId mapId: Int,
              xMin: Int, yMin: Int,
              xMax: Int, yMax: Int) -> WalkabilityGrid? {
        grids.first {
            $0.mapId == mapId
                && $0.covers(xMin: xMin, yMin: yMin, xMax: xMax, yMax: yMax)
        }
    }

    /// Returns the whole-map walkability grid for `mapId`, or `nil` when none
    /// has been baked. Used by the closest-teleport walking-distance ranking.
    func globalGrid(forMapId mapId: Int) -> WalkabilityGrid? {
        globalGrids.first { $0.mapId == mapId }
    }

    /// Returns a BFS walking-distance map over the whole-map grid for `mapId`
    /// from `origin`, paired with the grid itself, or `nil` when no whole-map
    /// grid exists. Results are memoised per (mapId, origin) so repeated UI
    /// queries for the same clue are free.
    ///
    /// `origin` should already be snapped to a walkable tile (see
    /// `WalkabilityGrid.nearestWalkable`).
    func walkingDistanceMap(forMapId mapId: Int,
                            from origin: (x: Int, y: Int))
        -> (grid: WalkabilityGrid, dist: [Int])? {
        guard let grid = globalGrid(forMapId: mapId) else { return nil }

        if let hit = distanceCache.first(where: {
            $0.mapId == mapId && $0.x == origin.x && $0.y == origin.y
        }) {
            return (grid, hit.dist)
        }

        let dist = BFSPathfinder.distanceMap(from: origin, over: grid)
        distanceCache.insert((mapId, origin.x, origin.y, dist), at: 0)
        if distanceCache.count > distanceCacheCapacity {
            distanceCache.removeLast()
        }
        return (grid, dist)
    }
}
