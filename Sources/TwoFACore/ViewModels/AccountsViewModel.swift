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
    @Published public var sheet: Sheet?
    @Published public var errorMessage: String?

    public let repository: AccountRepository
    private var timer: AnyCancellable?

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
            rebuildRows()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    public func add(name: String, group: String, note: String, secret: String) -> Bool {
        do {
            _ = try repository.add(name: name, group: group, note: note, secret: secret)
            sheet = nil
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
            load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    public func copyCode(_ code: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(code, forType: .string)
    }

    private func filteredAccounts() -> [Account] {
        guard selectedGroup != "All" else { return accounts }
        return accounts.filter { $0.group == selectedGroup }
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
