import SwiftUI

public struct AccountEditorView: View {
    public enum Mode {
        case add
        case edit(Account)
    }

    let mode: Mode
    @ObservedObject var viewModel: AccountsViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var group: String
    @State private var note: String
    @State private var secret: String = ""
    @State private var localError: String?

    public init(mode: Mode, viewModel: AccountsViewModel) {
        self.mode = mode
        self.viewModel = viewModel
        switch mode {
        case .add:
            _name = State(initialValue: "")
            _group = State(initialValue: "")
            _note = State(initialValue: "")
        case .edit(let account):
            _name = State(initialValue: account.name)
            _group = State(initialValue: account.group)
            _note = State(initialValue: account.note)
        }
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .font(.title2.bold())

            VStack(alignment: .leading, spacing: 8) {
                TextField("Name", text: $name)
                    .disabled(isEdit)
                TextField("Group", text: $group)
                TextField("Note", text: $note)
                SecureField(secretPlaceholder, text: $secret)
                Text(isEdit ? "Leave secret blank to keep the existing one." : "Whitespace is ignored and lowercase is accepted.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if let localError {
                Text(localError)
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            HStack {
                Spacer()
                Button("Cancel") {
                    dismissSheet()
                }
                Button(primaryButtonTitle) {
                    save()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(width: 380)
    }

    private var title: String {
        isEdit ? "Edit Account" : "Add Account"
    }

    private var primaryButtonTitle: String {
        isEdit ? "Save" : "Add"
    }

    private var secretPlaceholder: String {
        isEdit ? "New Secret (optional)" : "Secret"
    }

    private var isEdit: Bool {
        if case .edit = mode { return true }
        return false
    }

    private func save() {
        viewModel.errorMessage = nil
        localError = nil
        let success: Bool
        switch mode {
        case .add:
            success = viewModel.add(name: name, group: group, note: note, secret: secret)
        case .edit(let account):
            success = viewModel.update(account: account, group: group, note: note, replacementSecret: secret)
        }

        if success {
            dismissSheet()
        } else {
            localError = viewModel.errorMessage
        }
    }

    private func dismissSheet() {
        viewModel.sheet = nil
        dismiss()
    }
}
