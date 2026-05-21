import AppKit
import SwiftUI

public struct SettingsView: View {
    @ObservedObject var viewModel: AccountsViewModel
    @Environment(\.dismiss) private var dismiss

    public init(viewModel: AccountsViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Settings")
                .font(.title2.bold())

            VStack(alignment: .leading, spacing: 6) {
                Text("Data file")
                    .font(.headline)
                Text(viewModel.metadataPath)
                    .font(.caption.monospaced())
                    .textSelection(.enabled)
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Backup and migration")
                    .font(.headline)
                Text("Exports include raw TOTP secrets. Keep backup files private.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                HStack {
                    Button("Export…") {
                        exportAccounts()
                    }
                    Button("Import and Merge…") {
                        chooseImportFile(merge: true)
                    }
                    Button("Replace from File…") {
                        chooseImportFile(merge: false)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Security")
                    .font(.headline)
                Text("Secrets are stored in ~/.2fa/accounts.json for compatibility with the Go version and hidden in this UI.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("Copied codes are cleared from the clipboard after 30 seconds if unchanged.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            HStack {
                Button("Quit 2fa") {
                    NSApplication.shared.terminate(nil)
                }
                Spacer()
                Button("Done") {
                    viewModel.sheet = nil
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(width: 520, height: 360)
    }

    private func exportAccounts() {
        activateForPanel()
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.json]
        panel.nameFieldStringValue = "accounts.json"
        panel.canCreateDirectories = true
        panel.level = .floating

        guard panel.runModal() == .OK, let url = panel.url else { return }
        _ = viewModel.exportAccounts(to: url)
    }

    private func chooseImportFile(merge: Bool) {
        activateForPanel()
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.json]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.level = .floating

        guard panel.runModal() == .OK, let url = panel.url else { return }
        if merge {
            _ = viewModel.importAccounts(from: url, merge: true)
        } else if confirmReplace() {
            _ = viewModel.importAccounts(from: url, merge: false)
        }
    }

    private func confirmReplace() -> Bool {
        activateForPanel()
        let alert = NSAlert()
        alert.messageText = "Replace existing accounts?"
        alert.informativeText = "This creates a timestamped backup first, then replaces ~/.2fa/accounts.json with the selected file."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Replace")
        alert.addButton(withTitle: "Cancel")
        return alert.runModal() == .alertFirstButtonReturn
    }

    private func activateForPanel() {
        NSApplication.shared.activate(ignoringOtherApps: true)
    }
}
