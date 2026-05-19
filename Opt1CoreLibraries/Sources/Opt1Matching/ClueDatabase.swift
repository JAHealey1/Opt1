import Foundation

// MARK: - Data Model

public struct ClueSolution: Codable, Identifiable {
    public var id: String
    public var type: String        // "cryptic" | "coordinate" | "anagram" | "map" | "compass" | "emote"
    public var difficulty: String? // "easy" | "medium" | "hard" | "elite" | "master" — optional for back-compat
    public var clue: String        // The raw clue text as it appears in-game
    public var solution: String    // Human-readable solution
    public var location: String?   // Named location (e.g. "Varrock Palace")
    public var coordinates: String? // RS coordinates if applicable (e.g. "3213, 3424")
    public var mapId: Int?         // RS map ID for tile lookup: 28 = surface, -1 = underground/default, 695 = Arc
    public var imageRef: String?   // Base filename for bundled map clue images (MapImages/)
    public var travel: String?     // Travel suggestions, bullet-points joined with " • "
    public var confidence: Double? // Populated by FuzzyMatcher at query time
    /// Alternate OCR text patterns for the compact scan parchment (small scroll).
    /// The compact scroll uses different wording than the large scroll clue text,
    /// so entries can supply known alternates (e.g. "The crater in the Wilderness"
    /// for the Wilderness Crater scan) that the matcher checks before fuzzy fallback.
    public var scanTextAliases: [String]?
    /// Known orb scan range in paces (scan clues only). Used to validate the
    /// live OCR-detected range and fall back to this value when OCR is wrong.
    public var scanRange: Int?

    // MARK: - Emote clue fields

    /// Items the player must equip, in order (emote clues only).
    /// e.g. ["Iron med helm", "Emerald ring", "Leather gloves"]
    public var emoteItems: [String]?
    /// Emote steps to perform, in sequence (emote clues only).
    /// Each inner array is one step; multiple entries mean alternatives are accepted.
    /// Easy: one step  — e.g. [["Clap"]] or [["Bow", "Curtsy"]]
    /// Medium: two steps — e.g. [["Beckon"], ["Bow", "Curtsy"]]
    ///   Step 1 summons Uri; step 2 must be performed before speaking to Uri.
    public var emoteSteps: [[String]]?
    /// Name of the hidey-hole object for this emote location.
    /// e.g. "Rock (hidey-hole) (Wizards' Tower)"
    public var hideyHoleName: String?
    /// Game-tile coordinates of the hidey-hole object.
    /// e.g. "3099,3188" — single tile, not a polygon.
    public var hideyHoleCoords: String?
    /// True when a double agent spawns on performing the emote (hard and master clues).
    public var hasFight: Bool?

    // MARK: - Anagram clue fields

    /// Challenge scroll question posed by the NPC after solving the anagram
    /// (anagram clues only, when the NPC has a challenge scroll).
    public var challengeQuestion: String?
    /// Correct answer to the challenge scroll question.
    public var challengeAnswer: String?

    // MARK: - Shared

    /// NPC name associated with this clue. Populated on anagram entries (the
    /// NPC to speak to) and challenge entries (the NPC that poses the question).
    /// Maps to the "npc" JSON key for compatibility with existing challenge entries.
    public var npcName: String?

    public init(
        id: String, type: String, difficulty: String? = nil,
        clue: String, solution: String, location: String? = nil,
        coordinates: String? = nil, mapId: Int? = nil, imageRef: String? = nil,
        travel: String? = nil, confidence: Double? = nil,
        scanTextAliases: [String]? = nil, scanRange: Int? = nil,
        emoteItems: [String]? = nil, emoteSteps: [[String]]? = nil,
        hideyHoleName: String? = nil, hideyHoleCoords: String? = nil,
        hasFight: Bool? = nil, challengeQuestion: String? = nil,
        challengeAnswer: String? = nil, npcName: String? = nil
    ) {
        self.id = id
        self.type = type
        self.difficulty = difficulty
        self.clue = clue
        self.solution = solution
        self.location = location
        self.coordinates = coordinates
        self.mapId = mapId
        self.imageRef = imageRef
        self.travel = travel
        self.confidence = confidence
        self.scanTextAliases = scanTextAliases
        self.scanRange = scanRange
        self.emoteItems = emoteItems
        self.emoteSteps = emoteSteps
        self.hideyHoleName = hideyHoleName
        self.hideyHoleCoords = hideyHoleCoords
        self.hasFight = hasFight
        self.challengeQuestion = challengeQuestion
        self.challengeAnswer = challengeAnswer
        self.npcName = npcName
    }

    enum CodingKeys: String, CodingKey {
        case id, type, difficulty, clue, solution, location, coordinates, mapId,
             imageRef, travel, confidence, scanTextAliases, scanRange
        case emoteItems, emoteSteps, hideyHoleName, hideyHoleCoords, hasFight
        case challengeQuestion, challengeAnswer
        case npcName = "npc"
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        type = try c.decode(String.self, forKey: .type)
        difficulty = try c.decodeIfPresent(String.self, forKey: .difficulty)
        clue = try c.decode(String.self, forKey: .clue)
        solution = try c.decode(String.self, forKey: .solution)
        location = try c.decodeIfPresent(String.self, forKey: .location)
        coordinates = try c.decodeIfPresent(String.self, forKey: .coordinates)
        mapId = try c.decodeIfPresent(Int.self, forKey: .mapId)
        imageRef = try c.decodeIfPresent(String.self, forKey: .imageRef)
        travel = try c.decodeIfPresent(String.self, forKey: .travel)
        confidence = try c.decodeIfPresent(Double.self, forKey: .confidence)
        scanTextAliases = try c.decodeIfPresent([String].self, forKey: .scanTextAliases)
        scanRange = try Self.decodeScanRange(from: c)
        emoteItems = try c.decodeIfPresent([String].self, forKey: .emoteItems)
        emoteSteps = try c.decodeIfPresent([[String]].self, forKey: .emoteSteps)
        hideyHoleName = try c.decodeIfPresent(String.self, forKey: .hideyHoleName)
        hideyHoleCoords = try c.decodeIfPresent(String.self, forKey: .hideyHoleCoords)
        hasFight = try c.decodeIfPresent(Bool.self, forKey: .hasFight)
        challengeQuestion = try c.decodeIfPresent(String.self, forKey: .challengeQuestion)
        challengeAnswer = try c.decodeIfPresent(String.self, forKey: .challengeAnswer)
        npcName = try c.decodeIfPresent(String.self, forKey: .npcName)
    }

    /// `clues.json` uses quoted scan ranges (`"22"`) in addition to numeric JSON.
    private static func decodeScanRange(from c: KeyedDecodingContainer<CodingKeys>) throws -> Int? {
        guard c.contains(.scanRange) else { return nil }
        if try c.decodeNil(forKey: .scanRange) { return nil }
        if let i = try? c.decode(Int.self, forKey: .scanRange) { return i }
        if let s = try? c.decode(String.self, forKey: .scanRange) {
            let t = s.trimmingCharacters(in: .whitespacesAndNewlines)
            return Int(t)
        }
        return nil
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(type, forKey: .type)
        try c.encodeIfPresent(difficulty, forKey: .difficulty)
        try c.encode(clue, forKey: .clue)
        try c.encode(solution, forKey: .solution)
        try c.encodeIfPresent(location, forKey: .location)
        try c.encodeIfPresent(coordinates, forKey: .coordinates)
        try c.encodeIfPresent(mapId, forKey: .mapId)
        try c.encodeIfPresent(imageRef, forKey: .imageRef)
        try c.encodeIfPresent(travel, forKey: .travel)
        try c.encodeIfPresent(confidence, forKey: .confidence)
        try c.encodeIfPresent(scanTextAliases, forKey: .scanTextAliases)
        try c.encodeIfPresent(scanRange, forKey: .scanRange)
        try c.encodeIfPresent(emoteItems, forKey: .emoteItems)
        try c.encodeIfPresent(emoteSteps, forKey: .emoteSteps)
        try c.encodeIfPresent(hideyHoleName, forKey: .hideyHoleName)
        try c.encodeIfPresent(hideyHoleCoords, forKey: .hideyHoleCoords)
        try c.encodeIfPresent(hasFight, forKey: .hasFight)
        try c.encodeIfPresent(challengeQuestion, forKey: .challengeQuestion)
        try c.encodeIfPresent(challengeAnswer, forKey: .challengeAnswer)
        try c.encodeIfPresent(npcName, forKey: .npcName)
    }
}

// MARK: - Database

/// Loads and caches the bundled clue database from clues.json.
/// Phase 3: Populated with full RS3 clue data via scrape_clues.py.
public final class ClueDatabase {

    public static let shared = ClueDatabase()
    private let resourceBundle: Bundle
    public private(set) var clues: [ClueSolution] = []

    /// Pre-computed corpus for `FuzzyMatcher.bestMatch` — excludes types that
    /// have their own dedicated detection paths (map, compass, scan) and are
    /// never reached by the general text-matching branch. Rebuilt whenever
    /// `load()` replaces `clues`, so trigram/normalised-text data stays in
    /// lockstep with the underlying list.
    public private(set) var textCorpus: ClueCorpus = ClueCorpus(clues: [])

    private static let bestMatchExcludedTypes: Set<String> = ["map", "compass", "scan"]

    public init(resourceBundle: Bundle? = nil) {
        self.resourceBundle = resourceBundle ?? .module
    }

    public func load() {
        guard let url = resourceBundle.url(forResource: "clues", withExtension: "json") else {
            print("[Opt1] clues.json not found in bundle")
            return
        }
        do {
            let data = try Data(contentsOf: url)
            clues = try JSONDecoder().decode([ClueSolution].self, from: data)
            let textClues = clues.filter { !Self.bestMatchExcludedTypes.contains($0.type) }
            textCorpus = ClueCorpus(clues: textClues)
            print("[Opt1] Loaded \(clues.count) clues (\(textClues.count) text-matchable)")
        } catch {
            print("[Opt1] Failed to load clue database: \(error)")
        }
    }
}

