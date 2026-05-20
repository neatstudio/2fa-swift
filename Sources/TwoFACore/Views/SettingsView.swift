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
                Text("Metadata")
                    .font(.headline)
                Text(viewModel.metadataPath)
                    .font(.caption.monospaced())
                    .textSelection(.enabled)
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Secrets")
                    .font(.headline)
                Text("Stored in the same ~/.2fa/accounts.json file used by the Go version. Raw secrets are hidden in this UI.")
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
        .frame(width: 420, height: 260)
    }
}
