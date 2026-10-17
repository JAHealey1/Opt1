import Testing
import Foundation
import Opt1Matching
@testable import Opt1

@Suite("ScanFilterState survivingOrdered")
@MainActor
struct ScanFilterStateTests {

    private func scanSpot(id: String, x: Int, y: Int) -> ClueSolution {
        ClueSolution(
            id: id, type: "scan", clue: "scan", solution: "dig",
            location: "test", coordinates: "\(x), \(y)", mapId: 28
        )
    }

    private func withScanNextSpotEnabled<T>(_ body: () -> T) -> T {
        let key = AppSettings.Keys.scanNextSpotEnabled
        let prior = UserDefaults.standard.object(forKey: key)
        UserDefaults.standard.set(true, forKey: key)
        defer {
            if let prior {
                UserDefaults.standard.set(prior, forKey: key)
            } else {
                UserDefaults.standard.removeObject(forKey: key)
            }
        }
        return body()
    }

    private func withScanNextSpotDisabled<T>(_ body: () -> T) -> T {
        let key = AppSettings.Keys.scanNextSpotEnabled
        let prior = UserDefaults.standard.object(forKey: key)
        UserDefaults.standard.set(false, forKey: key)
        defer {
            if let prior {
                UserDefaults.standard.set(prior, forKey: key)
            } else {
                UserDefaults.standard.removeObject(forKey: key)
            }
        }
        return body()
    }

    @Test("survivingOrdered sorts by Chebyshev distance to recommendation, ties by id")
    func sortedByChebyshevFromRecommendation() {
        withScanNextSpotEnabled {
            let spots = [
                scanSpot(id: "far", x: 50, y: 50),
                scanSpot(id: "mid", x: 12, y: 10),
                scanSpot(id: "near", x: 11, y: 10),
                scanSpot(id: "tie-b", x: 10, y: 11),
                scanSpot(id: "tie-a", x: 10, y: 9),
            ]
            let state = ScanFilterState(region: "test", scanRange: "10", spots: spots)
            guard let rec = state.recommendedStep else {
                Issue.record("Expected a recommended step with scan guidance enabled")
                return
            }
            let origin = (x: rec.x, y: rec.y)
            var lastDist = -1
            var lastID = ""
            for spot in state.survivingOrdered {
                let d = ScanPulseFilter.chebyshev(from: origin, to: (spot.x, spot.y))
                #expect(d >= lastDist)
                if d == lastDist {
                    #expect(spot.id > lastID)
                }
                lastDist = d
                lastID = spot.id
            }
            #expect(state.survivingOrdered.count == spots.count)
        }
    }

    @Test("confirmPulse removes eliminated ids from survivingOrdered")
    func eliminatedAbsentAfterConfirm() {
        withScanNextSpotEnabled {
            let spots = [
                scanSpot(id: "triple", x: 5, y: 5),
                scanSpot(id: "single", x: 100, y: 100),
            ]
            let state = ScanFilterState(region: "test", scanRange: "10", spots: spots)
            state.setPendingPos((0, 0))
            state.confirmPulse(.triple)
            #expect(state.survivingIDs == ["triple"])
            let orderedIDs = Set(state.survivingOrdered.map(\.id))
            #expect(orderedIDs == state.survivingIDs)
            #expect(!orderedIDs.contains("single"))
        }
    }

    @Test("without recommendation, survivingOrdered uses stable allCoords order")
    func stableOrderWithoutRecommendation() {
        withScanNextSpotDisabled {
            let spots = [
                scanSpot(id: "c", x: 8, y: 8),
                scanSpot(id: "a", x: 9, y: 9),
                scanSpot(id: "b", x: 7, y: 7),
            ]
            let state = ScanFilterState(region: "test", scanRange: "10", spots: spots)
            state.setPendingPos((0, 0))
            state.confirmPulse(.triple)
            #expect(state.recommendedStep == nil)
            #expect(state.survivingOrdered.map(\.id) == ["c", "a", "b"])
            #expect(Set(state.survivingOrdered.map(\.id)) == state.survivingIDs)
        }
    }

    @Test("clearAll resets survivingOrdered with survivingIDs")
    func clearAllResetsOrdered() {
        withScanNextSpotEnabled {
            let spots = [
                scanSpot(id: "a", x: 10, y: 10),
                scanSpot(id: "b", x: 20, y: 20),
            ]
            let state = ScanFilterState(region: "test", scanRange: "10", spots: spots)
            state.setPendingPos((0, 0))
            state.confirmPulse(.triple)
            #expect(!state.survivingOrdered.isEmpty)
            state.clearAll()
            #expect(state.survivingIDs.isEmpty)
            #expect(state.survivingOrdered.map(\.id) == ["a", "b"])
        }
    }
}
