import Testing
@testable import Opt1

@Suite("Teleport keybind revision counter", .serialized)
struct AppSettingsKeybindRevisionTests {

    private let defaultsScope = TeleportKeybindTestDefaults.Scope()

    @Test("setGroupSteps bumps teleportKeybindsRevision")
    func setGroupStepsBumpsRevision() {
        let groupId = "opt1_test_set_group"
        defer { AppSettings.removeGroupSteps(forGroupId: groupId) }
        let before = defaultsScope.revisionSnapshot()
        AppSettings.setGroupSteps(["P"], forGroupId: groupId)
        #expect(defaultsScope.revisionSnapshot() > before)
    }

    @Test("removeGroupSteps bumps teleportKeybindsRevision")
    func removeGroupStepsBumpsRevision() {
        let groupId = "opt1_test_remove_group"
        AppSettings.setGroupSteps(["P"], forGroupId: groupId)
        let before = defaultsScope.revisionSnapshot()
        AppSettings.removeGroupSteps(forGroupId: groupId)
        #expect(defaultsScope.revisionSnapshot() > before)
    }

    @Test("setSpotSteps bumps teleportKeybindsRevision")
    func setSpotStepsBumpsRevision() {
        let spotId = "opt1_test_set_spot"
        defer { AppSettings.removeSpotSteps(forSpotId: spotId) }
        let before = defaultsScope.revisionSnapshot()
        AppSettings.setSpotSteps(["P"], forSpotId: spotId)
        #expect(defaultsScope.revisionSnapshot() > before)
    }

    @Test("removeSpotSteps bumps teleportKeybindsRevision")
    func removeSpotStepsBumpsRevision() {
        let spotId = "opt1_test_remove_spot"
        AppSettings.setSpotSteps(["P"], forSpotId: spotId)
        let before = defaultsScope.revisionSnapshot()
        AppSettings.removeSpotSteps(forSpotId: spotId)
        #expect(defaultsScope.revisionSnapshot() > before)
    }
}
