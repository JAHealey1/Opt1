import AppKit
import SwiftUI

// MARK: - Model

@MainActor
final class PipelineStatusBannerModel: ObservableObject {
    @Published var message: String = ""
}

// MARK: - View

private struct PipelineStatusBannerView: View {
    @ObservedObject var model: PipelineStatusBannerModel

    var body: some View {
        HStack(spacing: 8) {
            ProgressView()
                .controlSize(.small)
                .tint(OverlayTheme.gold)
            Text(model.message)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(OverlayTheme.textPrimary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(OverlayTheme.bgPrimary.opacity(OverlayTheme.bgPrimaryOp))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(OverlayTheme.goldBorder.opacity(0.35), lineWidth: 1.0)
        )
    }
}

// MARK: - Controller

/// Lightweight floating banner that shows spinner + status text during the
/// detection pipeline ("Checking for clues…", "Solving: …", etc.).
/// Intentionally independent of puzzle-box concerns.
@MainActor
final class PipelineStatusBanner {

    private var panel:   NSPanel?
    private var hosting: NSHostingView<AnyView>?
    private var model    = PipelineStatusBannerModel()

    // MARK: - API

    /// Show the banner centred above the game window.
    func showStatus(_ message: String, near windowFrame: CGRect) {
        cancel()
        model = PipelineStatusBannerModel()
        model.message = message

        let bannerW: CGFloat = 220
        let bannerH: CGFloat = 36
        let cgRect = CGRect(
            x: windowFrame.midX - bannerW / 2,
            y: windowFrame.minY + 40,
            width:  bannerW,
            height: bannerH
        )
        let frame = PuzzleSnipDesktop.cgRectToAppKit(cgRect)

        let p = makePanel(frame: frame)
        let h = NSHostingView(rootView: AnyView(PipelineStatusBannerView(model: model)))
        h.frame = p.contentView?.bounds ?? .zero
        h.autoresizingMask = [.width, .height]
        p.contentView?.addSubview(h)
        p.orderFront(nil)

        panel   = p
        hosting = h
    }

    func updateStatus(_ message: String) {
        model.message = message
    }

    func cancel() {
        panel?.orderOut(nil)
        panel?.close()
        panel   = nil
        hosting = nil
    }

    // MARK: - Helpers

    private func makePanel(frame: NSRect) -> NSPanel {
        OverlayPanelFactory.makeFloatingPanel(frame: frame, passthrough: true)
    }

}
