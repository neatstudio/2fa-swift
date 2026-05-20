import Foundation

public struct AccountDisplayRow: Identifiable, Equatable {
    public let account: Account
    public let code: String
    public let remaining: Int

    public var id: String { account.id }

    public init(account: Account, code: String, remaining: Int) {
        self.account = account
        self.code = code
        self.remaining = remaining
    }
}
