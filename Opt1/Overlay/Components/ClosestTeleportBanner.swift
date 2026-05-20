import AppKit
import SwiftUI

// MARK: - ClosestTeleportBanner

/// Multi-row teleport suggestion section.
///
/// The parent owns the `spots` array (pre-sorted by distance, pre-filtered for
/// disabled IDs) so promotion on disable is handled externally by recomputing
/// the sorted list. This component renders `spots.prefix(maxRows)` rows and
/// manages the keybind sheet internally.
///
/// Row 0 gets the gold-tinted background and the `rowLabel` micro-caption.
/// Subsequent rows use a transparent background and slightly dimmer text.
/// Every row includes an "I don't have this" button that calls `onDisable`.
struct ClosestTeleportBanner: View {
    let spots: [(spot: TeleportSpot, tiles: Double)]
    let onDisable: (TeleportSpot) -> Void
    var maxRows: Int = 2
    var rowLabel: String = "Closest teleport"

    @State private var keybindSheetTarget: TeleportSpot? = nil
    @State private var groupSteps: [String: [String]] = AppSettings.teleportGroupSteps
    @State private var spotSteps:  [String: [String]] = AppSettings.teleportSpotSteps

    var body: some View {
        let visible = Array(spots.prefix(maxRows))
        if !visible.isEmpty {
            VStack(spacing: 0) {
                ForEach(Array(visible.enumerated()), id: \.element.spot.id) { idx, entry in
                    teleportRow(entry.spot, tiles: entry.tiles, isFirst: idx == 0)
                    if idx < visible.count - 1 {
                        Divider().opacity(0.12).padding(.horizontal, 12)
                    }
                }
            }
            .sheet(item: $keybindSheetTarget) { spot in
                let isSpot = AppSettings.perSpotKeybindGroups.contains(spot.groupId)
                TeleportInstructionSheet(
                    scopeId:     isSpot ? spot.id        : spot.groupId,
                    scopeName:   isSpot ? spot.name      : spot.groupName,
                    contextLine: isSpot
                        ? "\(spot.name) · \(spot.groupName)"
                        : "Applies to all \(spot.groupName) teleports",
                    knownCode:   spot.code,
                    isSpotLevel: isSpot
                )
            }
            .onReceive(NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)) { _ in
                groupSteps = AppSettings.teleportGroupSteps
                spotSteps  = AppSettings.teleportSpotSteps
            }
        }
    }

    @ViewBuilder
    private func teleportRow(_ spot: TeleportSpot, tiles: Double, isFirst: Bool) -> some View {
        let steps = resolvedSteps(for: spot)

        HStack(spacing: 8) {
            if let iconName = spot.resolvedIcon,
               let cg = TeleportSpriteCache.shared.image(named: iconName) {
                Image(nsImage: NSImage(cgImage: cg, size: NSSize(width: 20, height: 20)))
                    .frame(width: 20, height: 20)
            } else {
                Image(systemName: "arrow.triangle.swap")
                    .font(.system(size: 12))
                    .foregroundColor(OverlayTheme.gold.opacity(0.7))
                    .frame(width: 20, height: 20)
            }

            VStack(alignment: .leading, spacing: 1) {
                if isFirst {
                    Text(rowLabel)
                        .font(.system(size: 8, design: .monospaced))
                        .foregroundColor(OverlayTheme.textSecondary.opacity(0.6))
                }
                Text(spot.name)
                    .font(.system(size: isFirst ? 11 : 10, weight: .semibold, design: .monospaced))
                    .foregroundColor(isFirst ? OverlayTheme.gold : OverlayTheme.gold.opacity(0.65))
                Text(spot.groupName)
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(OverlayTheme.textSecondary)
                if let seq = keybindSequence(steps: steps, code: spot.code) {
                    Text(seq)
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundColor(OverlayTheme.gold.opacity(0.75))
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("\(Int(tiles.rounded())) tiles")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(OverlayTheme.textSecondary)
                    .padding(.horizontal, 6).padding(.vertical, 2)
                    .background(Capsule().fill(OverlayTheme.gold.opacity(isFirst ? 0.12 : 0.07)))

                Button { keybindSheetTarget = spot } label: {
                    Text(steps.isEmpty ? "Add keybind" : "Edit keybind")
                        .font(.system(size: 8))
                        .foregroundColor(OverlayTheme.gold.opacity(0.7))
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(Capsule().fill(OverlayTheme.gold.opacity(0.08)))
                        .overlay(Capsule().strokeBorder(OverlayTheme.gold.opacity(0.2), lineWidth: 0.5))
                }
                .buttonStyle(.plain)
                .help(AppSettings.perSpotKeybindGroups.contains(spot.groupId)
                    ? "Set custom keybind pre-steps for \(spot.name)."
                    : "Set custom keybind pre-steps for all \(spot.groupName) teleports.")

                Button { onDisable(spot) } label: {
                    Text("I don't have this")
                        .font(.system(size: 8))
                        .foregroundColor(.white.opacity(0.5))
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(Capsule().fill(.white.opacity(0.08)))
                        .overlay(Capsule().strokeBorder(.white.opacity(0.12), lineWidth: 0.5))
                }
                .buttonStyle(.plain)
                .help("Exclude this teleport from suggestions. Re-enable it in Settings → Scan Teleports.")
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(isFirst ? OverlayTheme.gold.opacity(0.06) : Color.clear)
    }

    private func resolvedSteps(for spot: TeleportSpot) -> [String] {
        AppSettings.perSpotKeybindGroups.contains(spot.groupId)
            ? spotSteps[spot.id] ?? []
            : groupSteps[spot.groupId] ?? []
    }
}
