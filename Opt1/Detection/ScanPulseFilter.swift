import Foundation

// MARK: - Scan Pulse

/// The three pulse states an orb emits relative to a player position.
enum ScanPulse: CaseIterable, Hashable {
    case single, double, triple

    var label: String {
        switch self {
        case .single: return "Single"
        case .double: return "Double"
        case .triple: return "Triple"
        }
    }
}

// MARK: - Scan Pulse Filter

/// Filters scan clue dig spots based on the observed orb pulse and the player's
/// current tile position.
///
/// Scan mechanics use Chebyshev distance (max of horizontal and vertical
/// tile offsets). Given scan range R:
///   - Triple pulse: player is within R tiles of the spot.
///   - Double pulse: player is between R+1 and 2R tiles away.
///   - Single pulse: player is beyond 2R tiles away.
///
/// "Different level" is excluded — it requires per-spot floor data not currently
/// stored in `clues.json`.
struct ScanPulseFilter {

    // MARK: - Distance

    /// Chebyshev distance between two game-tile positions.
    static func chebyshev(from player: (x: Int, y: Int),
                          to spot: (x: Int, y: Int)) -> Int {
        max(abs(player.x - spot.x), abs(player.y - spot.y))
    }

    // MARK: - Pulse Calculation

    /// Maps a Chebyshev tile distance to its pulse for the given scan `range`.
    static func pulse(forDistance d: Int, range: Int) -> ScanPulse {
        if d <= range         { return .triple }
        if d <= range * 2     { return .double }
        return .single
    }

    /// Returns the pulse the player would observe from `player` for a spot at `spot`
    /// with the given scan `range`.
    static func pulse(from player: (x: Int, y: Int),
                      to spot: (x: Int, y: Int),
                      range: Int) -> ScanPulse {
        pulse(forDistance: chebyshev(from: player, to: spot), range: range)
    }

    // MARK: - Origin tolerance

    /// The set of pulses a spot could produce when scanned from *any* tile
    /// within `tolerance` Chebyshev tiles of `player`.
    ///
    /// The marked origin is an approximate map tap, not the player's exact game
    /// tile, so the true scan position lies somewhere in a small box around it.
    /// This mirrors ClueTrainer's area-based narrowing (`area_pulse`): a spot
    /// survives if it matches the observed pulse from anywhere in that box.
    ///
    /// Pulse depends only on Chebyshev distance, which changes by at most
    /// `tolerance` under a Chebyshev move of radius `tolerance`. The reachable
    /// distances are therefore exactly the integer interval
    /// `[max(0, d - tolerance), d + tolerance]`, so it suffices to sample the
    /// interval endpoints and any band boundary that falls inside it.
    static func possiblePulses(from player: (x: Int, y: Int),
                               to spot: (x: Int, y: Int),
                               range: Int,
                               tolerance: Int) -> Set<ScanPulse> {
        let d = chebyshev(from: player, to: spot)
        guard tolerance > 0 else { return [pulse(forDistance: d, range: range)] }
        let lo = max(0, d - tolerance)
        let hi = d + tolerance
        // Pulse is monotonic in distance; the distinct pulses over [lo, hi] are
        // captured by the endpoints plus the band-edge distances inside the range.
        let samples = [lo, hi, range, range + 1, range * 2, range * 2 + 1]
            .filter { $0 >= lo && $0 <= hi }
        return Set(samples.map { pulse(forDistance: $0, range: range) })
    }

    // MARK: - Filtering

    /// Returns the set of spot IDs that could produce `pulse` when scanned from
    /// `player` with the given `range`.
    ///
    /// - Parameters:
    ///   - coords:    Pre-parsed spot coordinates as `(id, x, y)` triples.
    ///   - player:    Player's marked game-tile position.
    ///   - range:     Effective scan range (including any familiar bonuses).
    ///   - pulse:     The observed pulse to filter for.
    ///   - tolerance: Chebyshev radius of origin uncertainty (default `0` =
    ///                exact-tile match). A spot survives if it matches `pulse`
    ///                from any tile within this radius of `player`.
    static func survivingIDs(from coords: [(id: String, x: Int, y: Int)],
                              player: (x: Int, y: Int),
                              range: Int,
                              pulse: ScanPulse,
                              tolerance: Int = 0) -> Set<String> {
        Set(coords
            .filter {
                Self.possiblePulses(from: player, to: ($0.x, $0.y),
                                    range: range, tolerance: tolerance)
                    .contains(pulse)
            }
            .map(\.id)
        )
    }
}
