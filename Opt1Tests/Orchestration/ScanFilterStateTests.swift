import Testing
import Opt1Matching
@testable import Opt1

@Suite("ScanFilterState")
@MainActor
struct ScanFilterStateTests {

    @Test("allCoords carries explicit plane and maps nil to surface")
    func allCoordsPlaneMapping() {
        let spots = [
            ClueSolution(
                id: "plane0", type: "scan",
                clue: "This scroll will work in Test Region. Orb scan range: 10 paces.",
                solution: "Lower level spot.", location: "Test Region",
                coordinates: "3200,3200", plane: 0
            ),
            ClueSolution(
                id: "plane2", type: "scan",
                clue: "This scroll will work in Test Region. Orb scan range: 10 paces.",
                solution: "Top level spot.", location: "Test Region",
                coordinates: "3201,3201", plane: 2
            ),
            ClueSolution(
                id: "planeNil", type: "scan",
                clue: "This scroll will work in Test Region. Orb scan range: 10 paces.",
                solution: "Surface spot.", location: "Test Region",
                coordinates: "3202,3202", plane: nil
            ),
        ]
        let state = ScanFilterState(region: "Test Region", scanRange: "10", spots: spots)
        let planesByID = Dictionary(uniqueKeysWithValues: state.allCoords.map { ($0.id, $0.plane) })
        #expect(planesByID["plane0"] == 0)
        #expect(planesByID["plane2"] == 2)
        #expect(planesByID["planeNil"] == 0)
    }

    private func scanSpot(id: String, coordinates: String, plane: Int?) -> ClueSolution {
        ClueSolution(
            id: id, type: "scan",
            clue: "This scroll will work in Test Region. Orb scan range: 10 paces.",
            solution: "Spot \(id).", location: "Test Region",
            coordinates: coordinates, plane: plane
        )
    }

    @Test("different-floor observation eliminates every spot on the player's floor")
    func differentFloorObservationEliminatesPlayerFloor() {
        let spots = [
            scanSpot(id: "ground", coordinates: "3205,3205", plane: 0),
            scanSpot(id: "upper", coordinates: "3205,3205", plane: 2),
        ]
        let state = ScanFilterState(region: "Test Region", scanRange: "10", spots: spots)
        state.setPendingPos((3200, 3200))
        state.confirmPulse(.triple, differentLevel: true)
        #expect(state.survivingIDs == Set(["upper"]))
    }

    @Test("same-floor observation eliminates every spot on the other floor")
    func sameFloorObservationEliminatesOtherFloor() {
        let spots = [
            scanSpot(id: "ground", coordinates: "3205,3205", plane: 0),
            scanSpot(id: "upper", coordinates: "3205,3205", plane: 2),
        ]
        let state = ScanFilterState(region: "Test Region", scanRange: "10", spots: spots)
        state.setPendingPos((3200, 3200))
        state.confirmPulse(.triple, differentLevel: false)
        #expect(state.survivingIDs == Set(["ground"]))
    }

    @Test("differentLevel flag is per observation and intersects across pulses")
    func perObservationDifferentLevelIntersects() {
        let spots = [
            scanSpot(id: "ground", coordinates: "3205,3205", plane: 0),
            scanSpot(id: "upper", coordinates: "3205,3205", plane: 2),
        ]
        let state = ScanFilterState(region: "Test Region", scanRange: "10", spots: spots)
        state.setPendingPos((3200, 3200))
        state.confirmPulse(.triple, differentLevel: true)
        state.setPendingPos((3200, 3200))
        state.confirmPulse(.triple, differentLevel: false)
        #expect(state.survivingIDs.isEmpty)
        #expect(state.observations[0].differentLevel)
        #expect(!state.observations[1].differentLevel)
    }
}
