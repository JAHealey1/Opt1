import AppKit
import SwiftUI
import Opt1Matching

// MARK: - MapClueView

/// Overlay card for map clues. Shows the bundled clue image alongside a world
/// map centred on the dig spot and the solution text below.
struct MapClueView: View {
    let clue: ClueSolution
    var onClose: (() -> Void)? = nil

    @State private var disabledTeleportIds: Set<String> = AppSettings.disabledScanTeleportIds
    @State private var mapHasTiles: Bool? = nil

    var body: some View {
        VStack(spacing: 0) {
            OverlayHeaderBar(
                type: "MAP",
                badges: [BadgeSpec.difficulty(clue.difficulty)].compactMap { $0 },
                onClose: onClose
            )
            Divider().opacity(0.25)

            if let img = clueImage {
                clueImageView(img)
                Divider().opacity(0.25)
            }

            if clue.coordinates != nil {
                WorldMapSection(clue: clue, viewportHeight: 130, hasTiles: $mapHasTiles)
                Divider().opacity(0.25)
            }

            solutionSection

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

    private func clueImageView(_ img: NSImage) -> some View {
        Image(nsImage: img)
            .resizable()
            .scaledToFit()
            .frame(maxWidth: .infinity)
            .frame(height: 180)
            .clipped()
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
    }

    @ViewBuilder
    private var solutionSection: some View {
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
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var clueImage: NSImage? {
        guard let ref = clue.imageRef else { return nil }
        if let url = Bundle.main.url(forResource: ref, withExtension: nil, subdirectory: "MapImages") {
            return NSImage(contentsOf: url)
        }
        return NSImage(named: ref)
    }

    private var closestTeleports: [(spot: TeleportSpot, tiles: Double)] {
        clueClosestTeleports(for: clue, excluding: disabledTeleportIds)
    }

    private func disableTeleport(_ spot: TeleportSpot) {
        AppSettings.disableScanTeleport(id: spot.id)
        disabledTeleportIds = AppSettings.disabledScanTeleportIds
    }
}
