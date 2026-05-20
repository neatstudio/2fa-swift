import Foundation

public enum AccountRepositoryError: LocalizedError, Equatable {
    case emptyName
    case duplicateName(String)
    case missingSecret
    case accountNotFound
    case unreadableStore(String)
    case invalidImport(String)

    public var errorDescription: String? {
        switch self {
        case .emptyName:
            return "Name is required."
        case .duplicateName(let name):
            return "An account named \(name) already exists."
        case .missingSecret:
            return "Secret is required."
        case .accountNotFound:
            return "Account was not found."
        case .unreadableStore(let backupPath):
            return "The accounts file could not be read. A backup was saved at \(backupPath)."
        case .invalidImport(let reason):
            return "Import failed: \(reason)"
        }
    }
}

public final class AccountRepository {
    public let metadataURL: URL
    private let totpService: TOTPService
    private let fileManager: FileManager
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    public init(
        metadataURL: URL,
        totpService: TOTPService = TOTPService(),
        fileManager: FileManager = .default
    ) {
        self.metadataURL = metadataURL
        self.totpService = totpService
        self.fileManager = fileManager
        encoder = DateCoding.makeEncoder()
        decoder = DateCoding.makeDecoder()
    }

    public static func live() -> AccountRepository {
        AccountRepository(
            metadataURL: FileManager.default.homeDirectoryForCurrentUser
                .appendingPathComponent(".2fa", isDirectory: true)
                .appendingPathComponent("accounts.json")
        )
    }

    public func load() throws -> [Account] {
        guard fileManager.fileExists(atPath: metadataURL.path) else {
            return []
        }

        do {
            let data = try Data(contentsOf: metadataURL)
            let snapshot = try decoder.decode(AccountStoreSnapshot.self, from: data)
            return try validate(snapshot.accounts.map(normalizedLoadedAccount))
        } catch {
            let backupURL = try backupDamagedStore()
            throw AccountRepositoryError.unreadableStore(backupURL.path)
        }
    }

    public func add(name: String, group: String, note: String, secret: String, now: Date = Date()) throws -> Account {
        var accounts = try load()
        let normalizedName = AccountInput.normalizedName(name)
        guard !normalizedName.isEmpty else { throw AccountRepositoryError.emptyName }
        guard !accounts.contains(where: { $0.name == normalizedName }) else {
            throw AccountRepositoryError.duplicateName(normalizedName)
        }

        let normalizedSecret = Base32.normalize(secret)
        guard !normalizedSecret.isEmpty else { throw AccountRepositoryError.missingSecret }
        _ = try totpService.code(secret: normalizedSecret, date: now)

        let account = Account(
            name: normalizedName,
            group: AccountInput.normalizedGroup(group),
            note: AccountInput.normalizedNote(note),
            secret: normalizedSecret,
            createdAt: now,
            updatedAt: now
        )
        accounts.append(account)
        try save(accounts)
        return account
    }

    public func update(name: String, group: String, note: String, replacementSecret: String, now: Date = Date()) throws -> Account {
        var accounts = try load()
        guard let index = accounts.firstIndex(where: { $0.name == name }) else {
            throw AccountRepositoryError.accountNotFound
        }

        let normalizedSecret = Base32.normalize(replacementSecret)
        if !normalizedSecret.isEmpty {
            _ = try totpService.code(secret: normalizedSecret, date: now)
            accounts[index].secret = normalizedSecret
        }

        accounts[index].group = AccountInput.normalizedGroup(group)
        accounts[index].note = AccountInput.normalizedNote(note)
        accounts[index].updatedAt = now
        try save(accounts)
        return accounts[index]
    }

    public func delete(name: String) throws {
        var accounts = try load()
        guard let index = accounts.firstIndex(where: { $0.name == name }) else {
            throw AccountRepositoryError.accountNotFound
        }
        accounts.remove(at: index)
        try save(accounts)
    }

    public func export(to destinationURL: URL) throws {
        let accounts = try load()
        let data = try encoder.encode(AccountStoreSnapshot(accounts: accounts))
        try data.write(to: destinationURL, options: .atomic)
        try? fileManager.setAttributes([.posixPermissions: 0o600], ofItemAtPath: destinationURL.path)
    }

    public func importAccounts(from sourceURL: URL, merge: Bool, now: Date = Date()) throws -> Int {
        let data = try Data(contentsOf: sourceURL)
        let snapshot: AccountStoreSnapshot
        do {
            snapshot = try decoder.decode(AccountStoreSnapshot.self, from: data)
        } catch {
            throw AccountRepositoryError.invalidImport("The selected file is not a valid accounts.json file.")
        }

        let importedAccounts: [Account]
        do {
            importedAccounts = try validate(snapshot.accounts.map(normalizedLoadedAccount))
            for account in importedAccounts {
                _ = try totpService.code(secret: account.secret, date: now)
            }
        } catch {
            throw AccountRepositoryError.invalidImport(error.localizedDescription)
        }

        let result: [Account]
        if merge {
            var existing = try load()
            for account in importedAccounts {
                if existing.contains(where: { $0.name == account.name }) {
                    throw AccountRepositoryError.duplicateName(account.name)
                }
                existing.append(account)
            }
            result = existing
        } else {
            result = importedAccounts
        }

        try save(result)
        return importedAccounts.count
    }

    public func displayRows(accounts: [Account], date: Date = Date()) throws -> [AccountDisplayRow] {
        try accounts.map { account in
            AccountDisplayRow(
                account: account,
                code: try totpService.code(secret: account.secret, date: date),
                remaining: totpService.remainingSeconds(date: date)
            )
        }
    }

    private func save(_ accounts: [Account]) throws {
        let validAccounts = try validate(accounts)
        let directory = metadataURL.deletingLastPathComponent()
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true, attributes: [.posixPermissions: 0o700])
        if fileManager.fileExists(atPath: metadataURL.path) {
            _ = try createBackup(suffix: "backup")
        }
        let data = try encoder.encode(AccountStoreSnapshot(accounts: validAccounts))
        let temporaryURL = directory.appendingPathComponent(".accounts.json.tmp")
        try data.write(to: temporaryURL, options: .atomic)
        try fileManager.setAttributes([.posixPermissions: 0o600], ofItemAtPath: temporaryURL.path)
        if fileManager.fileExists(atPath: metadataURL.path) {
            _ = try fileManager.replaceItemAt(metadataURL, withItemAt: temporaryURL)
        } else {
            try fileManager.moveItem(at: temporaryURL, to: metadataURL)
        }
        try fileManager.setAttributes([.posixPermissions: 0o600], ofItemAtPath: metadataURL.path)
    }

    private func validate(_ accounts: [Account]) throws -> [Account] {
        var names = Set<String>()
        for account in accounts {
            guard !account.name.isEmpty else { throw AccountRepositoryError.emptyName }
            guard !account.secret.isEmpty else { throw AccountRepositoryError.missingSecret }
            guard names.insert(account.name).inserted else {
                throw AccountRepositoryError.duplicateName(account.name)
            }
        }
        return accounts
    }

    private func normalizedLoadedAccount(_ account: Account) -> Account {
        Account(
            name: AccountInput.normalizedName(account.name),
            group: AccountInput.normalizedGroup(account.group),
            note: AccountInput.normalizedNote(account.note),
            secret: Base32.normalize(account.secret),
            createdAt: account.createdAt,
            updatedAt: account.updatedAt
        )
    }

    private func backupDamagedStore() throws -> URL {
        try createBackup(suffix: "damaged")
    }

    private func createBackup(suffix: String) throws -> URL {
        let directory = metadataURL.deletingLastPathComponent()
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true, attributes: [.posixPermissions: 0o700])
        for index in 0..<1000 {
            let name = index == 0
                ? "accounts.\(timestamp()).\(suffix).json"
                : "accounts.\(timestamp()).\(suffix).\(index).json"
            let backupURL = directory.appendingPathComponent(name)
            if !fileManager.fileExists(atPath: backupURL.path) {
                try fileManager.copyItem(at: metadataURL, to: backupURL)
                try? fileManager.setAttributes([.posixPermissions: 0o600], ofItemAtPath: backupURL.path)
                return backupURL
            }
        }
        let backupURL = directory.appendingPathComponent("accounts.\(UUID().uuidString).\(suffix).json")
        try fileManager.copyItem(at: metadataURL, to: backupURL)
        try? fileManager.setAttributes([.posixPermissions: 0o600], ofItemAtPath: backupURL.path)
        return backupURL
    }

    private func timestamp() -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyyMMdd-HHmmss-SSS"
        return formatter.string(from: Date())
    }
}
