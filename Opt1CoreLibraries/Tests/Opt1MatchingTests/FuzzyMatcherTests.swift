import Testing
@testable import Opt1Matching

@Suite("FuzzyMatcher")
struct FuzzyMatcherTests {

    // MARK: - Levenshtein similarity

    @Test("Identical strings → similarity 1.0")
    func identicalStrings() throws {
        let m = FuzzyMatcher()
        #expect(m.levenshteinSimilarity("hello", "hello") == 1.0)
    }

    @Test("Both empty → similarity 1.0")
    func bothEmpty() throws {
        let m = FuzzyMatcher()
        #expect(m.levenshteinSimilarity("", "") == 1.0)
    }

    @Test("One empty → similarity 0.0")
    func oneEmpty() throws {
        let m = FuzzyMatcher()
        #expect(m.levenshteinSimilarity("hello", "") == 0.0)
        #expect(m.levenshteinSimilarity("", "hello") == 0.0)
    }

    @Test("Known edit distances", arguments: [
        ("kitten", "sitting", 1.0 - 3.0 / 7.0),   // 3 edits, max len 7
        ("abc", "abd", 1.0 - 1.0 / 3.0),           // 1 edit, max len 3
        ("ab", "ba", 1.0 - 2.0 / 2.0),             // 2 edits (swap), max len 2 → 0.0
    ] as [(String, String, Double)])
    func knownEditDistances(a: String, b: String, expected: Double) throws {
        let m = FuzzyMatcher()
        let actual = m.levenshteinSimilarity(a, b)
        #expect(abs(actual - expected) < 0.001)
    }

    @Test("Similarity is symmetric")
    func symmetry() throws {
        let m = FuzzyMatcher()
        let a = m.levenshteinSimilarity("runescape", "runscape")
        let b = m.levenshteinSimilarity("runscape", "runescape")
        #expect(abs(a - b) < 0.001)
    }

    // MARK: - bestMatch: standard clue lookup

    private func clue(_ id: String, _ type: String, _ text: String) -> ClueSolution {
        ClueSolution(id: id, type: type, clue: text, solution: "solution", location: nil,
                     coordinates: nil, mapId: nil, imageRef: nil,
                     travel: nil, confidence: nil)
    }

    @Test("bestMatch: exact observation matches clue at high confidence")
    func exactMatchHighConfidence() throws {
        let db = [clue("c1", "cryptic", "He who wields the most powerful wand")]
        var m = FuzzyMatcher()
        m.confidenceThreshold = 0.72
        let result = m.bestMatch(forAny: ["He who wields the most powerful wand"], in: ClueCorpus(clues: db))
        let match = try #require(result)
        #expect(match.clue.id == "c1")
        #expect(match.confidence >= 0.72)
    }

    @Test("bestMatch: below-threshold observation returns nil")
    func belowThresholdReturnsNil() throws {
        let db = [clue("c1", "cryptic", "He who wields the most powerful wand")]
        var m = FuzzyMatcher()
        m.confidenceThreshold = 0.99  // unreachably high
        let result = m.bestMatch(forAny: ["Completely unrelated text xyz"], in: ClueCorpus(clues: db))
        #expect(result == nil)
    }

    @Test("bestMatch: empty observations returns nil")
    func emptyObservationsNil() throws {
        let db = [clue("c1", "cryptic", "Some clue")]
        let m = FuzzyMatcher()
        let result = m.bestMatch(forAny: [], in: ClueCorpus(clues: db))
        #expect(result == nil)
    }

    @Test("bestMatch: empty database returns nil")
    func emptyDatabaseNil() throws {
        let m = FuzzyMatcher()
        let result = m.bestMatch(forAny: ["Some observation"], in: ClueCorpus(clues: []))
        #expect(result == nil)
    }

    // MARK: - Anagram matching

    private func anagramClue(_ id: String, _ phrase: String) -> ClueSolution {
        clue(id, "anagram", "This anagram reveals who to speak to next: \(phrase)")
    }

    @Test("Anagram: exact letter-sorted match returns confidence 1.0")
    func anagramExactMatch() throws {
        let db = [anagramClue("a1", "BANKER")]
        let m = FuzzyMatcher()
        let obs = ["This anagram reveals who to speak to next: BANKER"]
        let result = m.bestMatch(forAny: obs, in: ClueCorpus(clues: db))
        let match = try #require(result)
        #expect(match.clue.id == "a1")
        #expect(match.confidence >= 0.99)
    }

    @Test("Anagram: OCR near-miss still finds a match")
    func anagramNearMiss() throws {
        let db = [anagramClue("a1", "BANKER")]
        let m = FuzzyMatcher()
        // "BANKIR" — one char off from "BANKER"
        let obs = ["This anagram reveals who to speak to next: BANKIR"]
        let result = m.bestMatch(forAny: obs, in: ClueCorpus(clues: db))
        // Near-miss should resolve to the only candidate via suffix-only fallback.
        let match = try #require(result)
        #expect(match.clue.id == "a1")
    }

    @Test("Anagram: 'OK CO' matches Cook, not Oracle")
    func anagramCookNotOracle() throws {
        // Regression for user report: 'OK CO' was incorrectly identified as Oracle
        // ("ARE COL") instead of Cook because the full-text Levenshtein fallthrough
        // was dominated by the shared 44-char boilerplate prefix.
        let db = [
            anagramClue("cook", "OK CO"),
            anagramClue("oracle", "ARE COL"),
        ]
        let m = FuzzyMatcher()
        let obs = ["This anagram reveals who to speak to next: OK CO"]
        let result = m.bestMatch(forAny: obs, in: ClueCorpus(clues: db))
        let match = try #require(result)
        #expect(match.clue.id == "cook")
    }

    @Test("Anagram: boilerplate-only observation (no suffix) returns nil")
    func anagramNoSuffixReturnsNil() throws {
        let db = [anagramClue("a1", "BANKER")]
        let m = FuzzyMatcher()
        // Observation contains only the prefix line — cannot identify which anagram.
        let obs = ["This anagram reveals who to speak to next:"]
        let result = m.bestMatch(forAny: obs, in: ClueCorpus(clues: db))
        #expect(result == nil)
    }

    @Test("Anagram: unknown scramble (missing from DB) returns nil, not a wrong clue")
    func anagramMissingFromDBReturnsNil() throws {
        // When the correct anagram is absent from the DB, the matcher must not
        // return a plausible-looking but wrong match via boilerplate similarity.
        let db = [anagramClue("oracle", "ARE COL")]
        let m = FuzzyMatcher()
        let obs = ["This anagram reveals who to speak to next: OK CO"]
        let result = m.bestMatch(forAny: obs, in: ClueCorpus(clues: db))
        // Oracle should NOT be returned just because the boilerplate matches.
        #expect(result == nil)
    }

    // MARK: - Coordinate matching

    private func coordClue(_ id: String, _ text: String) -> ClueSolution {
        clue(id, "coordinate", text)
    }

    @Test("Coordinate: valid format matches against coordinate clue")
    func coordinateMatch() throws {
        let coordText = "02 degrees 48 minutes north, 09 degrees 33 minutes east"
        let db = [coordClue("coord1", coordText)]
        let m = FuzzyMatcher()
        let result = m.bestMatch(forAny: [coordText], in: ClueCorpus(clues: db))
        let match = try #require(result)
        #expect(match.clue.id == "coord1")
    }

    @Test("Coordinate: direction mismatch drops confidence")
    func coordinateDirectionMismatch() throws {
        let coordText = "02 degrees 48 minutes north, 09 degrees 33 minutes east"
        let wrong = "02 degrees 48 minutes south, 09 degrees 33 minutes west"
        let db = [coordClue("coord1", coordText)]
        let m = FuzzyMatcher()
        let result = m.bestMatch(forAny: [wrong], in: ClueCorpus(clues: db))
        // Mismatched lat/lon directions should produce no match (coordinateSimilarity returns 0)
        #expect(result == nil)
    }

    // MARK: - Scan matching

    private func scanClue(_ id: String, _ text: String, _ location: String) -> ClueSolution {
        ClueSolution(id: id, type: "scan", clue: text, solution: "scan",
                     location: location, coordinates: nil, mapId: nil,
                     imageRef: nil, travel: nil, confidence: nil)
    }

    @Test("scanMatches: location-name containment returns matching group")
    func scanMatchesLocation() throws {
        let db = [
            scanClue("s1", "This scroll will work in the Varrock area. Orb scan range: 30 paces.", "Varrock"),
            scanClue("s2", "This scroll will work in the Varrock area. Orb scan range: 30 paces.", "Varrock"),
            scanClue("s3", "This scroll will work in the Falador area. Orb scan range: 20 paces.", "Falador"),
        ]
        let m = FuzzyMatcher()
        let obs = ["This scroll will work in the Varrock area. Orb scan range: 30 paces."]
        let matches = m.scanMatches(forAny: obs, in: db)
        #expect(!matches.isEmpty)
        #expect(matches.allSatisfy { $0.location == "Varrock" })
    }

    @Test("scanMatches: no scan clues in database returns empty")
    func scanMatchesNoDB() throws {
        let db = [clue("c1", "cryptic", "Some cryptic clue")]
        let m = FuzzyMatcher()
        let matches = m.scanMatches(forAny: ["something"], in: db)
        #expect(matches.isEmpty)
    }

    // MARK: - Multi-observation window joining

    @Test("bestMatch: clue spanning multiple OCR lines matched via join")
    func multiLineJoin() throws {
        let fullText = "He who wields the most powerful wand can break through any barrier"
        let db = [clue("c1", "cryptic", fullText)]
        let m = FuzzyMatcher()
        // Split into two observations that together recreate the clue
        let obs = ["He who wields the most powerful wand",
                   "can break through any barrier"]
        let result = m.bestMatch(forAny: obs, in: ClueCorpus(clues: db))
        let match = try #require(result)
        #expect(match.clue.id == "c1")
    }

    // MARK: - Corpus regression (long skill / emote OCR splits)

    /// Exact `clue` strings from `clues.json` — regression anchors for multi-line Vision output.
    private enum CorpusClueText {
        static let skill1575 =
            "Those things I once held dear continue to fade. I look upon her face and barely know who she is. But her eyes... They are still so radiant."
        static let skill1575Solution =
            "Harvest a radiant memory on Dragontooth Island. A Dungeoneering cape can be used to teleport directly to the Dragontooth Island resource dungeon."
        static let emote0398 =
            "Salute in the Max Guild Garden. Beware of double agents! Have no items equipped when you do."
        static let emote0374 =
            "Cheer by the sulphur pit in the TzHaar City. Beware of double agents! Equip a fire cape, a Toktz-ket-xil and a spork."
        /// Different enough from `skill1575` that it should not steal the match.
        static let distractorSkill =
            "Being open to Chaos can raise your defences. It may also bring you closer to death. Take a moment to bottle this feeling."
    }

    private func skillClue(id: String, clue: String, solution: String = CorpusClueText.skill1575Solution) -> ClueSolution {
        ClueSolution(
            id: id, type: "skill", difficulty: "master", clue: clue, solution: solution,
            location: nil, coordinates: nil, mapId: nil, imageRef: nil, travel: nil, confidence: nil
        )
    }

    private func emoteClue(id: String, clue: String, solution: String, location: String?) -> ClueSolution {
        ClueSolution(
            id: id, type: "emote", difficulty: "master", clue: clue, solution: solution,
            location: location, coordinates: nil, mapId: 28, imageRef: nil, travel: nil, confidence: nil
        )
    }

    @Test("bestMatch: skill_1575 master riddle with garbled title + four body lines")
    func corpusSkill1575TitlePlusFourLines() throws {
        var m = FuzzyMatcher()
        m.confidenceThreshold = 0.72
        let db: [ClueSolution] = [
            skillClue(id: "skill_1575", clue: CorpusClueText.skill1575),
            skillClue(id: "skill_distractor", clue: CorpusClueText.distractorSkill,
                      solution: "dummy solution long enough"),
        ]
        let obs = [
            "MÜSTERRMIS CLME SRANI",
            "Those things I once held dear continue to fade.",
            "I look upon her face and barely know who she is.",
            "But her eyes...",
            "They are still so radiant.",
        ]
        let result = m.bestMatch(forAny: obs, in: ClueCorpus(clues: db))
        let match = try #require(result)
        #expect(match.clue.id == "skill_1575")
        #expect(match.confidence >= 0.72)
    }

    @Test("bestMatch: skill_1575 split into five body fragments (needs wide window / full join)")
    func corpusSkill1575FiveBodyFragments() throws {
        var m = FuzzyMatcher()
        m.confidenceThreshold = 0.72
        let db: [ClueSolution] = [
            skillClue(id: "skill_1575", clue: CorpusClueText.skill1575),
            skillClue(id: "skill_distractor", clue: CorpusClueText.distractorSkill,
                      solution: "other"),
        ]
        // Split first sentence across two observations (simulates Vision line wraps).
        let obs = [
            "MVSADOS LINE",
            "Those things I once held dear",
            "continue to fade.",
            "I look upon her face and barely know who she is.",
            "But her eyes...",
            "They are still so radiant.",
        ]
        let result = m.bestMatch(forAny: obs, in: ClueCorpus(clues: db))
        let match = try #require(result)
        #expect(match.clue.id == "skill_1575")
    }

    @Test("bestMatch: emote_0398 Max Guild Garden across three OCR lines")
    func corpusEmote0398ThreeLines() throws {
        var m = FuzzyMatcher()
        m.confidenceThreshold = 0.72
        let db: [ClueSolution] = [
            emoteClue(
                id: "emote_0398",
                clue: CorpusClueText.emote0398,
                solution: "Max Guild Garden",
                location: "Max Guild Garden"
            ),
            emoteClue(
                id: "other_emote",
                clue: "Wave in front of the entrance to the Grand Library of Menaphos. Beware of double agents!",
                solution: "Menaphos",
                location: "Menaphos"
            ),
        ]
        let obs = [
            "MUSTERRMIS TITLE",
            "Salute in the Max Guild Garden.",
            "Beware of double agents! Have no items equipped when you do.",
        ]
        let result = m.bestMatch(forAny: obs, in: ClueCorpus(clues: db))
        let match = try #require(result)
        #expect(match.clue.id == "emote_0398")
    }

    @Test("bestMatch: emote_0374 TzHaar sulphur pit in two lines (OCR-style split)")
    func corpusEmote0374TwoLines() throws {
        var m = FuzzyMatcher()
        m.confidenceThreshold = 0.72
        let db: [ClueSolution] = [
            emoteClue(
                id: "emote_0374",
                clue: CorpusClueText.emote0374,
                solution: "TzHaar City",
                location: "TzHaar City"
            ),
            emoteClue(
                id: "other_emote",
                clue: "Salute in the banana plantation. Beware of double agents! Equip a diamond ring.",
                solution: "Karamja",
                location: "Karamja"
            ),
        ]
        let obs = [
            "Cheer by the sulphur pit in the TzHaar City.",
            "Beware of double agents! Equip a fire cape, a Toktz-ket-xil and a spork.",
        ]
        let result = m.bestMatch(forAny: obs, in: ClueCorpus(clues: db))
        let match = try #require(result)
        #expect(match.clue.id == "emote_0374")
    }
}
