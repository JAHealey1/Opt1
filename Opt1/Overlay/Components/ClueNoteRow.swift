import SwiftUI
import AppKit

// MARK: - ClueNoteRow

/// A small contextual note displayed beneath a clue solution — used for
/// quest-conditional location changes or other caveats (e.g. "After Blood Runs
/// Deep, Queen Sigrid can be found on the 1st floor of Miscellania Castle.").
///
/// When `noteUrl` is supplied an "Open wiki" button appears alongside the text
/// that opens the URL in the default browser.
struct ClueNoteRow: View {
    let note: String
    var noteUrl: String? = nil

    var body: some View {
        HStack(alignment: .top, spacing: 6) {
            Image(systemName: "info.circle")
                .font(.system(size: 10))
                .foregroundColor(OverlayTheme.gold.opacity(0.65))
                .padding(.top, 1)

            VStack(alignment: .leading, spacing: 4) {
                Text(note)
                    .font(.system(size: 10).italic())
                    .foregroundColor(OverlayTheme.textSecondary.opacity(0.8))
                    .fixedSize(horizontal: false, vertical: true)

                if let urlString = noteUrl, let url = URL(string: urlString) {
                    Button {
                        NSWorkspace.shared.open(url)
                    } label: {
                        HStack(spacing: 3) {
                            Image(systemName: "arrow.up.right.square")
                                .font(.system(size: 8))
                            Text("Open wiki")
                                .font(.system(size: 9, design: .monospaced))
                        }
                        .foregroundColor(OverlayTheme.gold.opacity(0.8))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.top, 6)
        .padding(.bottom, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
