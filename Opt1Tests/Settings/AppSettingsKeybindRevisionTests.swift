import Foundation
import Testing
@testable import Opt1

@Suite("Teleport keybind revision counter")
struct AppSettingsKeybindRevisionTests {

    private var revisionKey: String { AppSettings.Keys.teleportKeybindsRevision }

    private func snapshotRevision() -> Int {
        UserDefaults.standard.integer(forKey: revisionKey)
    }

    @Test("setGroupSteps bumps teleportKeybindsRevision")
    func setGroupStepsBumpsRevision() {
        let groupId = "opt1_test_set_group"
        defer { AppSettings.removeGroupSteps(forGroupId: groupId) }
        let before = snapshotRevision()
        AppSettings.setGroupSteps(["P"], forGroupId: groupId)
        #expect(snapshotRevision() > before)
    }

    @Test("removeGroupSteps bumps teleportKeybindsRevision")
    func removeGroupStepsBumpsRevision() {
        let groupId = "opt1_test_remove_group"
        AppSettings.setGroupSteps(["P"], forGroupId: groupId)
        let before = snapshotRevision()
        AppSettings.removeGroupSteps(forGroupId: groupId)
        #expect(snapshotRevision() > before)
    }

    @Test("setSpotSteps bumps teleportKeybindsRevision")
    func setSpotStepsBumpsRevision() {
        let spotId = "opt1_test_set_spot"
        defer { AppSettings.removeSpotSteps(forSpotId: spotId) }
        let before = snapshotRevision()
        AppSettings.setSpotSteps(["P"], forSpotId: spotId)
        #expect(snapshotRevision() > before)
    }

    @Test("removeSpotSteps bumps teleportKeybindsRevision")
    func removeSpotStepsBumpsRevision() {
        let spotId = "opt1_test_remove_spot"
        AppSettings.setSpotSteps(["P"], forSpotId: spotId)
        let before = snapshotRevision()
        AppSettings.removeSpotSteps(forSpotId: spotId)
        #expect(snapshotRevision() > before)
    }
}
