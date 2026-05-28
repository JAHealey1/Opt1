import SwiftUI
import Opt1Matching

// MARK: - CoordinateClueView

/// Overlay card for coordinate clues. Displays the coordinate phrasing from the
/// in-game scroll and a world map centred on the dig spot.
struct CoordinateClueView: View {
    let clue: ClueSolution
    var onClose: (() -> Void)? = nil

    @State private var disabledTeleportIds: Set<String> = AppSettings.disabledScanTeleportIds
    @State private var mapHasTiles: Bool? = nil

    var body: some View {
        VStack(spacing: 0) {
            OverlayHeaderBar(
                type: "COORDINATE",
                badges: [BadgeSpec.difficulty(clue.difficulty)].compactMap { $0 },
                onClose: onClose
            )
            Divider().opacity(0.25)

            if clue.coordinates != nil {
                WorldMapSection(clue: clue, viewportHeight: 180, hasTiles: $mapHasTiles)
                Divider().opacity(0.25)
            }

            coordinateSection

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
    private var coordinateSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let loc = clue.location, !loc.isEmpty {
                Text(loc)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(OverlayTheme.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Text(clue.clue)
                .font(.system(size: 11))
                .foregroundColor(OverlayTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            Text("Dig here — bring a spade")
                .font(.system(size: 10))
                .foregroundColor(OverlayTheme.textSecondary.opacity(0.55))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
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
