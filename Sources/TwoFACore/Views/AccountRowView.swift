import SwiftUI

struct AccountRowView: View {
    let row: AccountDisplayRow
    @ObservedObject var viewModel: AccountsViewModel
    @State private var showingDeleteConfirmation = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(row.account.name)
                        .font(.headline)
                    Text(row.account.group)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if !row.account.note.isEmpty {
                        Text(row.account.note)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(row.code)
                        .font(.system(size: 26, weight: .semibold, design: .monospaced))
                    Text("\(row.remaining)s")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(row.remaining <= 5 ? .red : .secondary)
                }
            }

            HStack {
                Button("Copy") {
                    viewModel.copyCode(row.code)
                }
                Button("Edit") {
                    viewModel.sheet = .edit(row.account)
                }
                Button("Delete", role: .destructive) {
                    showingDeleteConfirmation = true
                }
                Spacer()
            }
            .buttonStyle(.borderless)
            .font(.caption)
        }
        .padding(10)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .confirmationDialog(
            "Delete \(row.account.name)?",
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                viewModel.delete(account: row.account)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This removes the account from ~/.2fa/accounts.json.")
        }
    }
}
