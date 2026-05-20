import Foundation

public struct Account: Identifiable, Codable, Equatable {
    public var name: String
    public var group: String
    public var note: String
    public var secret: String
    public let createdAt: Date
    public var updatedAt: Date

    public var id: String { name }

    public init(
        name: String,
        group: String,
        note: String,
        secret: String,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.name = name
        self.group = group
        self.note = note
        self.secret = secret
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    private enum CodingKeys: String, CodingKey {
        case name
        case group
        case note
        case secret
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

public struct AccountStoreSnapshot: Codable, Equatable {
    public var accounts: [Account]

    public init(accounts: [Account] = []) {
        self.accounts = accounts
    }
}

public enum AccountInput {
    public static let defaultGroup = "default"

    public static func normalizedName(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    public static func normalizedGroup(_ value: String) -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? defaultGroup : trimmed
    }

    public static func normalizedNote(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
