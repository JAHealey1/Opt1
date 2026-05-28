import SwiftUI
import Opt1Matching

// MARK: - CrypticClueView

/// Overlay card for cryptic and unknown-type clues.
/// Also acts as the fallback view for any type not handled by a dedicated view.
struct CrypticClueView: View {
    let clue: ClueSolution
    var onClose: (() -> Void)? = nil

    @State private var disabledTeleportIds: Set<String> = AppSettings.disabledScanTeleportIds
    @State private var mapHasTiles: Bool? = nil

    var body: some View {
        VStack(spacing: 0) {
            OverlayHeaderBar(
                type: clue.type.uppercased(),
                badges: [BadgeSpec.difficulty(clue.difficulty)].compactMap { $0 },
                onClose: onClose
            )
            Divider().opacity(0.25)

            if clue.coordinates != nil {
                WorldMapSection(clue: clue, hasTiles: $mapHasTiles)
                Divider().opacity(0.25)
            }

            solutionSection

            if let step = clue.secondStep {
                Divider().opacity(0.25)
                SecondStepSection(step: step)
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
    private var solutionSection: some View {
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

    private var closestTeleports: [(spot: TeleportSpot, tiles: Double)] {
        clueClosestTeleports(for: clue, excluding: disabledTeleportIds)
    }

    private func disableTeleport(_ spot: TeleportSpot) {
        AppSettings.disableScanTeleport(id: spot.id)
        disabledTeleportIds = AppSettings.disabledScanTeleportIds
    }
}
