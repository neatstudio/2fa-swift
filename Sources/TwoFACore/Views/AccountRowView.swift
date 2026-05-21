import SwiftUI

struct AccountRowView: View {
    let row: AccountDisplayRow
    @ObservedObject var viewModel: AccountsViewModel
    @State private var showingDeleteConfirmation = false

    var body: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 6) {
                    Text(row.account.name)
                        .font(.system(size: 13, weight: .semibold))
                        .lineLimit(1)
                    Text(row.account.group)
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1)
                        .background(Color(nsColor: .separatorColor).opacity(0.25))
                        .clipShape(Capsule())
                }

                if !row.account.note.isEmpty {
                    Text(row.account.note)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Text(row.code)
                .font(.system(size: 20, weight: .semibold, design: .monospaced))
                .textSelection(.enabled)

            Text("\(row.remaining)s")
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(row.remaining <= 5 ? .red : .secondary)
                .frame(width: 28, alignment: .trailing)

            HStack(spacing: 2) {
                Button {
                    viewModel.copyCode(row.code)
                } label: {
                    Image(systemName: "doc.on.doc")
                        .frame(width: 22, height: 18)
                }
                .help("Copy code")

                Menu {
                    Button("Edit") {
                        viewModel.sheet = .edit(row.account)
                    }
                    Button("Delete", role: .destructive) {
                        showingDeleteConfirmation = true
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .frame(width: 22, height: 18)
                }
                .menuStyle(.borderlessButton)
                .help("More")
            }
            .buttonStyle(.borderless)
            .font(.system(size: 11))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 7))
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
