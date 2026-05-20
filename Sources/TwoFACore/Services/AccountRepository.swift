import Foundation

public enum AccountRepositoryError: LocalizedError, Equatable {
    case emptyName
    case duplicateName(String)
    case missingSecret
    case accountNotFound

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
        let data = try Data(contentsOf: metadataURL)
        let snapshot = try decoder.decode(AccountStoreSnapshot.self, from: data)
        return snapshot.accounts.map(normalizedLoadedAccount)
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
        let directory = metadataURL.deletingLastPathComponent()
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true, attributes: [.posixPermissions: 0o700])
        let data = try encoder.encode(AccountStoreSnapshot(accounts: accounts))
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
}
