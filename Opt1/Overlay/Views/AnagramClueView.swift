import SwiftUI
import Opt1Matching

// MARK: - AnagramClueView

/// Overlay card for anagram clues. Shows the NPC to speak to, their location,
/// and the challenge scroll question/answer when present.
struct AnagramClueView: View {
    let clue: ClueSolution
    var onClose: (() -> Void)? = nil

    @State private var disabledTeleportIds: Set<String> = AppSettings.disabledScanTeleportIds
    @State private var mapHasTiles: Bool? = nil

    var body: some View {
        VStack(spacing: 0) {
            OverlayHeaderBar(
                type: "ANAGRAM",
                badges: [BadgeSpec.difficulty(clue.difficulty)].compactMap { $0 },
                onClose: onClose
            )
            Divider().opacity(0.25)

            if clue.coordinates != nil {
                WorldMapSection(clue: clue, hasTiles: $mapHasTiles)
                Divider().opacity(0.25)
            }

            npcSection

            if clue.challengeQuestion != nil || clue.secondStep != nil {
                Divider().opacity(0.25)
                challengeSection
            }

            if let travel = clue.travel, !travel.isEmpty {
                Divider().opacity(0.25)
                TravelRow(travel: travel)
            }

            if !closestTeleports.isEmpty && mapHasTiles != false {
                Divider().opacity(0.25)
                ClosestTeleportBanner(spots: closestTeleports, onDisable: disableTeleport)
            }

            CloseButton(action: onClose ?? {})
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: OverlayTheme.cornerRadius, style: .continuous)
                .fill(OverlayTheme.bgPrimary.opacity(OverlayTheme.bgPrimaryOp))
        )
        .overlay(
            RoundedRectangle(cornerRadius: OverlayTheme.cornerRadius, style: .continuous)
                .strokeBorder(OverlayTheme.goldBorder.opacity(0.50), lineWidth: OverlayTheme.borderWidth)
        )
        .onReceive(NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)) { _ in
            disabledTeleportIds = AppSettings.disabledScanTeleportIds
        }
    }

    @ViewBuilder
    private var npcSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 4) {
                Text(clue.solution)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(OverlayTheme.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                if let loc = clue.location,
                   !loc.isEmpty,
                   loc.lowercased() != clue.solution.lowercased() {
                    Text(loc)
                        .font(.system(size: 11))
                        .foregroundColor(OverlayTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)

            if let note = clue.note {
                Divider().opacity(0.15)
                ClueNoteRow(note: note, noteUrl: clue.noteUrl)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var challengeSection: some View {
        if let question = clue.challengeQuestion, let answer = clue.challengeAnswer {
            VStack(alignment: .leading, spacing: 6) {
                Text("CHALLENGE SCROLL")
                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                    .foregroundColor(OverlayTheme.textSecondary.opacity(0.7))

                Text(question)
                    .font(.system(size: 11))
                    .foregroundColor(OverlayTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                Text(answer)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(OverlayTheme.gold)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
        } else if let step = clue.secondStep {
            SecondStepSection(step: step)
        }
    }

    private var closestTeleports: [(spot: TeleportSpot, tiles: Double)] {
        clueClosestTeleports(for: clue, excluding: disabledTeleportIds)
    }

    private func disableTeleport(_ spot: TeleportSpot) {
        AppSettings.disableScanTeleport(id: spot.id)
        disabledTeleportIds = AppSettings.disabledScanTeleportIds
    }
}
