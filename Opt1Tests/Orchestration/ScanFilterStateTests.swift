import Testing
import Foundation
@testable import Opt1
import Opt1Matching

@Suite("ScanAssumptions mid-scan", .serialized)
struct ScanAssumptionsMidScanTests {

    @Test("second observation uses base range only for Meerkats filtering")
    @MainActor
    func meerkatsRangeAppliesOnlyToFirstObservationFilter() {
        let meerkatsKey = AppSettings.Keys.scanAssumeMeerkats
        let defaults = UserDefaults.standard
        let previousMeerkats = defaults.object(forKey: meerkatsKey)
        defaults.set(true, forKey: meerkatsKey)
        defer {
            if let previousMeerkats {
                defaults.set(previousMeerkats, forKey: meerkatsKey)
            } else {
                defaults.removeObject(forKey: meerkatsKey)
            }
        }

        let baseRange = 10
        let spots: [ClueSolution] = [
            ClueSolution(
                id: "A", type: "scan", clue: "", solution: "",
                coordinates: "0,0", scanRange: baseRange
            ),
            ClueSolution(
                id: "G", type: "scan", clue: "", solution: "",
                coordinates: "12,0", scanRange: baseRange
            ),
        ]
        let coords: [(id: String, x: Int, y: Int)] = [("A", 0, 0), ("G", 12, 0)]
        let state = ScanFilterState(region: "test", scanRange: "15", spots: spots)
        #expect(state.baseRange == baseRange)

        state.setPendingPos((0, 0))
        state.confirmPulse(.triple)
        state.setPendingPos((0, 0))
        state.confirmPulse(.triple)

        let afterFirst = ScanPulseFilter.survivingIDs(
            from: coords,
            player: (0, 0),
            range: baseRange + 5,
            pulse: .triple,
            tolerance: 1
        )
        let afterSecond = ScanPulseFilter.survivingIDs(
            from: coords,
            player: (0, 0),
            range: baseRange,
            pulse: .triple,
            tolerance: 1
        )
        #expect(state.survivingIDs == afterFirst.intersection(afterSecond))
        #expect(!state.survivingIDs.contains("G"))

        let wronglyBuffedSecond = ScanPulseFilter.survivingIDs(
            from: coords,
            player: (0, 0),
            range: baseRange + 5,
            pulse: .triple,
            tolerance: 1
        )
        #expect(wronglyBuffedSecond.contains("G"))
    }
}
