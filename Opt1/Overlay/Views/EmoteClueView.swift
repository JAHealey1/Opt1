import SwiftUI
import Opt1Matching

// MARK: - EmoteClueView

/// Overlay card for emote clues. Shows items to equip, emote steps to perform,
/// a double-agent warning when applicable, and the hidey-hole location.
struct EmoteClueView: View {
    let clue: ClueSolution
    var onClose: (() -> Void)? = nil

    @State private var disabledTeleportIds: Set<String> = AppSettings.disabledScanTeleportIds
    @State private var filledHideyHoles: Set<String>    = AppSettings.filledHideyHoles
    @State private var mapHasTiles: Bool? = nil

    var body: some View {
        VStack(spacing: 0) {
            OverlayHeaderBar(
                type: "EMOTE",
                badges: [BadgeSpec.difficulty(clue.difficulty)].compactMap { $0 },
                onClose: onClose
            )
            Divider().opacity(0.25)

            if clue.coordinates != nil {
                WorldMapSection(clue: clue, hideyHolePins: hideyHolePin, hasTiles: $mapHasTiles)
                Divider().opacity(0.25)
            }

            if clue.hasFight == true {
                fightWarning
            }

            equipSection
            Divider().opacity(0.15)
            emoteSection

            if let name = clue.hideyHoleName {
                Divider().opacity(0.15)
                hideyHoleRow(name: name)
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
            filledHideyHoles    = AppSettings.filledHideyHoles
        }
    }

    private var fightWarning: some View {
        HStack(spacing: 6) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 11))
                .foregroundColor(.red)
            Text("Beware of double agents!")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.red)
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.red.opacity(0.10))
    }

    @ViewBuilder
    private var equipSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("EQUIP")
                .font(.system(size: 8, weight: .bold, design: .monospaced))
                .foregroundColor(OverlayTheme.textSecondary.opacity(0.7))

            if let items = clue.emoteItems, !items.isEmpty {
                ItemChipRow(items: items)
            } else {
                Text("Nothing equipped")
                    .font(.system(size: 11).italic())
                    .foregroundColor(OverlayTheme.textSecondary.opacity(0.5))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var emoteSection: some View {
        let steps = clue.emoteSteps ?? []
        VStack(alignment: .leading, spacing: 6) {
            Text(steps.count > 1 ? "PERFORM IN ORDER" : "PERFORM")
                .font(.system(size: 8, weight: .bold, design: .monospaced))
                .foregroundColor(OverlayTheme.textSecondary.opacity(0.7))

            if steps.isEmpty {
                Text("No emote steps recorded")
                    .font(.system(size: 11).italic())
                    .foregroundColor(OverlayTheme.textSecondary.opacity(0.5))
            } else {
                EmoteStepList(steps: steps)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func hideyHoleRow(name: String) -> some View {
        let isFilled = filledHideyHoles.contains(name)
        return HStack(spacing: 8) {
            if let img = hideyHoleImage {
                Image(nsImage: img)
                    .resizable()
                    .interpolation(.medium)
                    .scaledToFit()
                    .frame(width: 32, height: 32)
                    .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
            } else {
                Image(systemName: "archivebox")
                    .font(.system(size: 14))
                    .foregroundColor(OverlayTheme.textSecondary.opacity(0.6))
                    .frame(width: 32, height: 32)
            }

            VStack(alignment: .leading, spacing: 1) {
                Text("HIDEY-HOLE")
                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                    .foregroundColor(OverlayTheme.textSecondary.opacity(0.6))
                Text(name)
                    .font(.system(size: 11))
                    .foregroundColor(OverlayTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            Button {
                AppSettings.toggleHideyHole(name: name)
                filledHideyHoles = AppSettings.filledHideyHoles
            } label: {
                HStack(spacing: 4) {
                    Text("Filled")
                        .font(.system(size: 10))
                        .foregroundColor(
                            isFilled
                                ? OverlayTheme.gold.opacity(0.85)
                                : OverlayTheme.textSecondary.opacity(0.4)
                        )
                    Image(systemName: isFilled ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 15))
                        .foregroundColor(
                            isFilled
                                ? OverlayTheme.gold
                                : OverlayTheme.textSecondary.opacity(0.35)
                        )
                        .contentTransition(.symbolEffect(.replace))
                }
            }
            .buttonStyle(.plain)
            .help(isFilled ? "Mark hidey-hole as not filled" : "Mark hidey-hole as filled")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private var hideyHoleImage: NSImage? {
        // Prefer the scraped imageRef; fall back to deriving it from the
        // name so old clues.json builds still find the image.
        let ref = clue.hideyHoleImageRef
            ?? clue.hideyHoleName?.replacingOccurrences(of: " ", with: "_")
        guard let ref else { return nil }
        if let url = Bundle.main.url(forResource: ref, withExtension: "png",
                                     subdirectory: "HideyHoleImages") {
            return NSImage(contentsOf: url)
        }
        return nil
    }

    private var hideyHolePin: [(x: Int, y: Int)] {
        guard let coords = clue.hideyHoleCoords,
              let (x, y) = parseClueCoords(coords) else { return [] }
        return [(x: x, y: y)]
    }

    private var closestTeleports: [(spot: TeleportSpot, tiles: Double)] {
        clueClosestTeleports(for: clue, excluding: disabledTeleportIds)
    }

    private func disableTeleport(_ spot: TeleportSpot) {
        AppSettings.disableScanTeleport(id: spot.id)
        disabledTeleportIds = AppSettings.disabledScanTeleportIds
    }
}
