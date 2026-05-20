import SwiftUI

public struct SettingsView: View {
    @ObservedObject var viewModel: AccountsViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingImportConfirmation = false
    @State private var pendingImportURL: URL?

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
        .confirmationDialog(
            "Replace existing accounts?",
            isPresented: $showingImportConfirmation,
            titleVisibility: .visible
        ) {
            Button("Replace", role: .destructive) {
                if let pendingImportURL {
                    _ = viewModel.importAccounts(from: pendingImportURL, merge: false)
                }
                pendingImportURL = nil
            }
            Button("Cancel", role: .cancel) {
                pendingImportURL = nil
            }
        } message: {
            Text("This creates a timestamped backup first, then replaces ~/.2fa/accounts.json with the selected file.")
        }
    }

    private func exportAccounts() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.json]
        panel.nameFieldStringValue = "accounts.json"
        panel.canCreateDirectories = true
        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            _ = viewModel.exportAccounts(to: url)
        }
    }

    private func chooseImportFile(merge: Bool) {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.json]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            if merge {
                _ = viewModel.importAccounts(from: url, merge: true)
            } else {
                pendingImportURL = url
                showingImportConfirmation = true
            }
        }
    }
}
