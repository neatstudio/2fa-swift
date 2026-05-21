import SwiftUI

public struct MenuBarRootView: View {
    @ObservedObject private var viewModel: AccountsViewModel

    public init(viewModel: AccountsViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        VStack(spacing: 8) {
            header
            searchBar
            messages
            content
            footer
        }
        .padding(10)
        .frame(width: 460, height: 600)
        .sheet(item: $viewModel.sheet) { sheet in
            switch sheet {
            case .add:
                AccountEditorView(mode: .add, viewModel: viewModel)
            case .edit(let account):
                AccountEditorView(mode: .edit(account), viewModel: viewModel)
            case .settings:
                SettingsView(viewModel: viewModel)
            }
        }
    }

    private var header: some View {
        HStack {
            Text("2fa")
                .font(.title2.bold())

            Spacer()

            Picker("Group", selection: $viewModel.selectedGroup) {
                Text("All").tag("All")
                ForEach(viewModel.groups, id: \.self) { group in
                    Text(group).tag(group)
                }
            }
            .frame(width: 150)

            Button {
                viewModel.sheet = .add
            } label: {
                Image(systemName: "plus")
            }
            .help("Add account")

            Button {
                viewModel.sheet = .settings
            } label: {
                Image(systemName: "gearshape")
            }
            .help("Settings")
        }
    }

    private var searchBar: some View {
        TextField("Search name, group, or note", text: $viewModel.searchText)
            .textFieldStyle(.roundedBorder)
    }

    @ViewBuilder
    private var messages: some View {
        if let errorMessage = viewModel.errorMessage {
            Text(errorMessage)
                .font(.caption)
                .foregroundStyle(.red)
                .frame(maxWidth: .infinity, alignment: .leading)
        } else if let statusMessage = viewModel.statusMessage {
            Text(statusMessage)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.accounts.isEmpty {
            EmptyStateView(title: "No accounts yet", message: "Add a 2FA account to start viewing codes.") {
                viewModel.sheet = .add
            }
        } else if viewModel.rows.isEmpty {
            EmptyStateView(title: "No matching accounts", message: "Clear search or choose another group.") {
                viewModel.searchText = ""
                viewModel.selectedGroup = "All"
            }
        } else {
            ScrollView {
                LazyVStack(spacing: 4) {
                    ForEach(viewModel.rows) { row in
                        AccountRowView(row: row, viewModel: viewModel)
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }

    private var footer: some View {
        HStack {
            Text("Using ~/.2fa/accounts.json")
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
        }
    }
}
