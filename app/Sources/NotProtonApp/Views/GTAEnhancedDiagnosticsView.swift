import AppKit
import SwiftUI

struct GTAEnhancedDiagnosticsView: View {
    let prefix: WinePrefix
    @Environment(\.dismiss) private var dismiss

    private var recentLog: String {
        [PrefixLog.launch, .wine].compactMap { log in
            try? String(contentsOf: log.url(for: prefix), encoding: .utf8)
        }.joined(separator: "\n").suffix(80_000).lowercased()
    }

    private var diagnosis: String {
        if recentLog.contains("err_gfx_d3d_nod3d12") || recentLog.contains("d3d12core.dll") {
            return "The log points to DirectX 12 initialization. Check that D3DMetal is selected for this game and try a supported CrossOver Preview if 26.3 still reports the error. A game or runner update may be required."
        }
        if recentLog.contains("rockstar") && (recentLog.contains("invalid request") || recentLog.contains("authentication")) {
            return "Rockstar authentication appears to have failed. Open the game from Steam, check that Rockstar Games Launcher can sign in, then retry. Gamebox cannot bypass Rockstar account checks."
        }
        if recentLog.isEmpty { return "No launch log is available yet. Launch the game from Steam once, then check again." }
        return "No known GTA V Enhanced signature was found in the recent logs. Open the launch and Wine logs for the exact failure."
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("GTA V Enhanced launch check").font(.title2.bold())
            Text(diagnosis).fixedSize(horizontal: false, vertical: true)
            Text("Steam Cloud and Rockstar cloud saves depend on their clients signing in successfully; this check does not change saves or game files.")
                .font(.callout).foregroundStyle(.secondary)
            HStack {
                Button("Open launch log") { NSWorkspace.shared.open(PrefixLog.launch.url(for: prefix)) }
                    .disabled(!FileManager.default.fileExists(atPath: PrefixLog.launch.url(for: prefix).path))
                Button("Open Wine log") { NSWorkspace.shared.open(PrefixLog.wine.url(for: prefix)) }
                    .disabled(!FileManager.default.fileExists(atPath: PrefixLog.wine.url(for: prefix).path))
                Spacer()
                Button("Done") { dismiss() }.keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .frame(width: 560)
    }
}
