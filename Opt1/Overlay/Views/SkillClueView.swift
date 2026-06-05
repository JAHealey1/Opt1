import SwiftUI
import Opt1Matching

// MARK: - SkillClueView

/// Overlay card for skill/challenge clues. Shows the task description and
/// an optional world map when a dig/interaction location is provided.
struct SkillClueView: View {
    let clue: ClueSolution
    var onClose: (() -> Void)? = nil

    @State private var disabledTeleportIds: Set<String> = AppSettings.disabledScanTeleportIds
    @State private var mapHasTiles: Bool? = nil

    var body: some View {
        VStack(spacing: 0) {
            OverlayHeaderBar(
                type: "SKILL",
                badges: [BadgeSpec.difficulty(clue.difficulty)].compactMap { $0 },
                onClose: onClose
            )
            Divider().opacity(0.25)

            taskSection

            if let requirements = clue.requirements, !requirements.isEmpty {
                Divider().opacity(0.25)
                requirementsSection(requirements)
            }

            // The map is only meaningful once a dig/interaction location is known.
            // Skill riddles currently lack coordinates on the wiki, so this stays
            // hidden until a location is added — matching the design.
            if clue.coordinates != nil {
                WorldMapSection(clue: clue, hasTiles: $mapHasTiles)
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
    private var taskSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("TASK")
                .font(.system(size: 8, weight: .bold, design: .monospaced))
                .foregroundColor(OverlayTheme.textSecondary.opacity(0.7))

            Text(clue.solution)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
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
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func requirementsSection(_ requirements: [String]) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("REQUIREMENTS")
                .font(.system(size: 8, weight: .bold, design: .monospaced))
                .foregroundColor(OverlayTheme.textSecondary.opacity(0.7))
                .padding(.horizontal, 12)

            ChipFlowLayout(spacing: 4) {
                ForEach(requirements, id: \.self) { req in
                    Text(req)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(OverlayTheme.gold.opacity(0.9))
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(Capsule().fill(OverlayTheme.gold.opacity(0.12)))
                        .overlay(Capsule().strokeBorder(OverlayTheme.gold.opacity(0.25), lineWidth: 0.5))
                }
            }
            .padding(.horizontal, 12)
        }
        .padding(.vertical, 8)
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
