import Testing
@testable import Opt1

@Suite("TeleportLayer badge text")
struct TeleportLayerTests {

    private func spot(
        groupId: String = "lodestones",
        spotId: String = "alkharid",
        code: String? = nil
    ) -> TeleportSpot {
        TeleportSpot(
            groupId: groupId,
            groupName: "Test",
            spotId: spotId,
            name: "Test Spot",
            icon: nil,
            x: 0,
            y: 0,
            level: 0,
            code: code
        )
    }

    @Test("No custom steps uses in-game code on badge")
    func defaultCodeOnly() {
        let s = spot(code: "M")
        #expect(TeleportLayer.badgeText(for: s, customSteps: []) == "M")
    }

    @Test("Custom pre-steps joined with in-game code")
    func customStepsWithCode() {
        let s = spot(code: "M")
        #expect(TeleportLayer.badgeText(for: s, customSteps: ["⌥5"]) == "⌥5 > M")
    }

    @Test("Custom steps without in-game code")
    func customStepsOnly() {
        let s = spot(code: nil)
        #expect(TeleportLayer.badgeText(for: s, customSteps: ["P", "⌥5"]) == "P > ⌥5")
    }

    @Test("Empty custom steps and nil code suppress badge")
    func noBadgeWhenEmpty() {
        let s = spot(code: nil)
        #expect(TeleportLayer.badgeText(for: s, customSteps: []) == nil)
    }

    @Test("Multi-token in-game code keeps first token only")
    func multiTokenCodeFirstToken() {
        let s = spot(code: "BIR DIP CLR ALP")
        #expect(TeleportLayer.badgeText(for: s, customSteps: []) == "BIR")
    }

    @Test("Custom steps join with normalized in-game code")
    func customStepsWithMultiTokenCode() {
        let s = spot(code: "BIR DIP CLR ALP")
        #expect(TeleportLayer.badgeText(for: s, customSteps: ["P"]) == "P > BIR")
    }

    @Test("Per-spot spellbook group honours caller-provided steps")
    func perSpotGroupStepsAtSeam() {
        let s = spot(groupId: "normalspellbook", spotId: "varrock", code: "2")
        let steps = ["P", "⌥5"]
        #expect(TeleportLayer.badgeText(for: s, customSteps: steps) == "P > ⌥5 > 2")
    }
}

@Suite("TeleportLayer keybind integration", .serialized)
struct TeleportLayerKeybindIntegrationTests {

    private let defaultsScope = TeleportKeybindTestDefaults.Scope()

    private func spot(
        groupId: String,
        spotId: String,
        code: String?
    ) -> TeleportSpot {
        TeleportSpot(
            groupId: groupId,
            groupName: "Test",
            spotId: spotId,
            name: "Test Spot",
            icon: nil,
            x: 0,
            y: 0,
            level: 0,
            code: code
        )
    }

    @Test("Group keybind steps resolve into badge text")
    func groupStepsIntegration() {
        let s = spot(groupId: "lodestones", spotId: "alkharid", code: "M")
        defer { AppSettings.removeGroupSteps(forGroupId: s.groupId) }
        AppSettings.setGroupSteps(["⌥5"], forGroupId: s.groupId)
        let steps = AppSettings.resolvedSteps(for: s)
        #expect(TeleportLayer.badgeText(for: s, customSteps: steps) == "⌥5 > M")
    }

    @Test("Per-spot keybind steps resolve into badge text")
    func perSpotStepsIntegration() {
        let s = spot(groupId: "normalspellbook", spotId: "varrock", code: "2")
        defer { AppSettings.removeSpotSteps(forSpotId: s.id) }
        AppSettings.setSpotSteps(["P"], forSpotId: s.id)
        let steps = AppSettings.resolvedSteps(for: s)
        #expect(TeleportLayer.badgeText(for: s, customSteps: steps) == "P > 2")
    }
}
