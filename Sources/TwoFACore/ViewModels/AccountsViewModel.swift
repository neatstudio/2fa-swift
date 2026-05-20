import AppKit
import Combine
import Foundation

@MainActor
public final class AccountsViewModel: ObservableObject {
    public enum Sheet: Identifiable {
        case add
        case edit(Account)
        case settings

        public var id: String {
            switch self {
            case .add:
                return "add"
            case .edit(let account):
                return "edit-\(account.id)"
            case .settings:
                return "settings"
            }
        }
    }

    @Published public private(set) var accounts: [Account] = []
    @Published public private(set) var rows: [AccountDisplayRow] = []
    @Published public var selectedGroup: String = "All" {
        didSet { rebuildRows() }
    }
    @Published public var searchText: String = "" {
        didSet { rebuildRows() }
    }
    @Published public var sheet: Sheet?
    @Published public var errorMessage: String?
    @Published public var statusMessage: String?

    public let repository: AccountRepository
    private var timer: AnyCancellable?
    private var clipboardClearWorkItem: DispatchWorkItem?

    public init(repository: AccountRepository) {
        self.repository = repository
        load()
        timer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.rebuildRows()
            }
    }

    public var groups: [String] {
        Array(Set(accounts.map(\.group))).sorted()
    }

    public var metadataPath: String {
        repository.metadataURL.path
    }

    public func load() {
        do {
            accounts = try repository.load()
            if selectedGroup != "All" && !groups.contains(selectedGroup) {
                selectedGroup = "All"
            }
            errorMessage = nil
            rebuildRows()
        } catch {
            accounts = []
            rows = []
            errorMessage = error.localizedDescription
        }
    }

    public func add(name: String, group: String, note: String, secret: String) -> Bool {
        do {
            _ = try repository.add(name: name, group: group, note: note, secret: secret)
            sheet = nil
            statusMessage = "Account added."
            load()
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    public func update(account: Account, group: String, note: String, replacementSecret: String) -> Bool {
        do {
            _ = try repository.update(name: account.name, group: group, note: note, replacementSecret: replacementSecret)
            sheet = nil
            statusMessage = "Account updated."
            load()
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    public func delete(account: Account) {
        do {
            try repository.delete(name: account.name)
            statusMessage = "Account deleted."
            load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    public func exportAccounts(to destinationURL: URL) -> Bool {
        do {
            try repository.export(to: destinationURL)
            statusMessage = "Exported accounts to \(destinationURL.path)."
            errorMessage = nil
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    public func importAccounts(from sourceURL: URL, merge: Bool) -> Bool {
        do {
            let count = try repository.importAccounts(from: sourceURL, merge: merge)
            statusMessage = merge ? "Imported \(count) accounts." : "Replaced data with \(count) accounts."
            load()
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    public func copyCode(_ code: String) {
        clipboardClearWorkItem?.cancel()
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(code, forType: .string)
        statusMessage = "Code copied. Clipboard clears in 30 seconds."

        let item = DispatchWorkItem { [code] in
            Task { @MainActor in
                if NSPasteboard.general.string(forType: .string) == code {
                    NSPasteboard.general.clearContents()
                }
            }
        }
        clipboardClearWorkItem = item
        DispatchQueue.main.asyncAfter(deadline: .now() + 30, execute: item)
    }

    private func filteredAccounts() -> [Account] {
        var result = selectedGroup == "All" ? accounts : accounts.filter { $0.group == selectedGroup }
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if !query.isEmpty {
            result = result.filter { account in
                account.name.lowercased().contains(query)
                    || account.group.lowercased().contains(query)
                    || account.note.lowercased().contains(query)
            }
        }
        return result
    }

    private func rebuildRows() {
        do {
            rows = try repository.displayRows(accounts: filteredAccounts())
        } catch {
            rows = []
            if !accounts.isEmpty {
                errorMessage = error.localizedDescription
            }
        }
    }
}
