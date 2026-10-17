import Testing
@testable import Opt1

@Suite("ScanPulseFilter")
struct ScanPulseFilterTests {

    private let player = (x: 0, y: 0)
    private let range = 10

    /// Same tile, different planes — both triple from the origin with range 10.
    private let sameTileTwoPlanes: [(id: String, x: Int, y: Int, plane: Int)] = [
        ("ground", 5, 5, 0),
        ("upper", 5, 5, 2),
    ]

    @Test("same floor keeps same-plane spots and drops different-plane spots")
    func sameFloorPlaneFilter() {
        let ids = ScanPulseFilter.survivingIDs(
            from: sameTileTwoPlanes,
            player: player,
            range: range,
            pulse: .triple,
            differentLevel: false
        )
        #expect(ids.contains("ground"))
        #expect(!ids.contains("upper"))
    }

    @Test("different floor drops same-plane spots and keeps different-plane spots")
    func differentFloorPlaneFilter() {
        let ids = ScanPulseFilter.survivingIDs(
            from: sameTileTwoPlanes,
            player: player,
            range: range,
            pulse: .triple,
            differentLevel: true
        )
        #expect(!ids.contains("ground"))
        #expect(ids.contains("upper"))
    }

    @Test("plane filter composes with the pulse filter")
    func planeFilterComposesWithPulseFilter() {
        let coords: [(id: String, x: Int, y: Int, plane: Int)] = [
            ("wrongPlaneTriple", 5, 5, 2),
            ("wrongPulseSamePlane", 50, 50, 0),
        ]
        let tripleSameFloor = ScanPulseFilter.survivingIDs(
            from: coords,
            player: player,
            range: range,
            pulse: .triple,
            differentLevel: false
        )
        #expect(!tripleSameFloor.contains("wrongPlaneTriple"))
        #expect(!tripleSameFloor.contains("wrongPulseSamePlane"))

        let tripleDifferentFloor = ScanPulseFilter.survivingIDs(
            from: coords,
            player: player,
            range: range,
            pulse: .triple,
            differentLevel: true
        )
        #expect(tripleDifferentFloor.contains("wrongPlaneTriple"))
        #expect(!tripleDifferentFloor.contains("wrongPulseSamePlane"))
    }

    @Test("default playerPlane and differentLevel match same-floor filtering")
    func defaultParametersSameAsSameFloor() {
        let allSurface: [(id: String, x: Int, y: Int, plane: Int)] = [
            ("a", 5, 5, 0),
            ("b", 6, 6, 0),
        ]
        let explicit = ScanPulseFilter.survivingIDs(
            from: allSurface,
            player: player,
            range: range,
            pulse: .triple,
            differentLevel: false,
            playerPlane: 0
        )
        let defaulted = ScanPulseFilter.survivingIDs(
            from: allSurface,
            player: player,
            range: range,
            pulse: .triple
        )
        #expect(explicit == defaulted)
    }
}
