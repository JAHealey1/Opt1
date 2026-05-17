import Testing
@testable import Opt1

@Suite("ClueScrollPipeline OCR helpers")
struct ClueScrollPipelineTests {

    // MARK: - stripActionPrefix (skill boilerplate)

    @Test("Standalone Complete-the-action line is dropped entirely")
    func stripActionPrefixDropsStandaloneLine() {
        let raw = [
            "MÜSTERRMIS CLME SRANI",
            "Complete the action to solve the clue:",
            "Those things I once held dear continue to fade.",
        ]
        let out = ClueScrollPipeline.stripActionPrefix(from: raw)
        #expect(!out.contains(where: { $0.localizedCaseInsensitiveContains("complete the action") }))
        #expect(out.contains(where: { $0.contains("Those things") }))
    }

    @Test("Prefix on same line as body leaves only the body")
    func stripActionPrefixSameLineTail() {
        let raw = [
            "Complete the action (memory): Those things I once held dear continue to fade.",
        ]
        let out = ClueScrollPipeline.stripActionPrefix(from: raw)
        #expect(out.count == 1)
        #expect(out[0].hasPrefix("Those things"))
        #expect(!out[0].localizedCaseInsensitiveContains("complete the action"))
    }

    @Test("Case-insensitive prefix stripping")
    func stripActionPrefixCaseInsensitive() {
        let raw = [
            "COMPLETE THE ACTION to solve the clue: Salute in the Max Guild Garden.",
        ]
        let out = ClueScrollPipeline.stripActionPrefix(from: raw)
        #expect(out.count == 1)
        #expect(out[0].hasPrefix("Salute"))
    }

    @Test("Chained: standalone prefix line plus title noise still yields readable clue lines")
    func stripActionPrefixMatchesLoggedSkillShape() {
        let raw = [
            "MÜSTERRMIS CLME SRANI",
            "Complete the action to solve the due:",
            "Those things I once held dear continue to fade.",
            "Ilook upon her face and barely know who she is.",
            "But her eyes... .",
            "They are still so radiant.",
        ]
        let out = ClueScrollPipeline.stripActionPrefix(from: raw)
        let joined = out.joined(separator: " ")
        #expect(joined.contains("Those things"))
        #expect(joined.contains("radiant"))
        #expect(!joined.localizedCaseInsensitiveContains("complete the action"))
    }
}
