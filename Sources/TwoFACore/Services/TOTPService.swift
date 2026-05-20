import CryptoKit
import Foundation

public enum TOTPError: LocalizedError, Equatable {
    case invalidDigits
    case invalidPeriod

    public var errorDescription: String? {
        switch self {
        case .invalidDigits:
            return "TOTP digits must be positive."
        case .invalidPeriod:
            return "TOTP period must be positive."
        }
    }
}

public struct TOTPService {
    public let period: Int
    public let digits: Int

    public init(period: Int = 30, digits: Int = 6) {
        self.period = period
        self.digits = digits
    }

    public func code(secret: String, date: Date = Date()) throws -> String {
        guard digits > 0 else { throw TOTPError.invalidDigits }
        guard period > 0 else { throw TOTPError.invalidPeriod }

        let keyData = try Base32.decode(secret)
        let counter = UInt64(floor(date.timeIntervalSince1970 / Double(period)))
        var counterBigEndian = counter.bigEndian
        let counterData = Data(bytes: &counterBigEndian, count: MemoryLayout<UInt64>.size)
        let signature = HMAC<Insecure.SHA1>.authenticationCode(
            for: counterData,
            using: SymmetricKey(data: keyData)
        )
        let hash = Array(signature)
        let offset = Int(hash[hash.count - 1] & 0x0f)
        let binary = ((Int(hash[offset]) & 0x7f) << 24)
            | ((Int(hash[offset + 1]) & 0xff) << 16)
            | ((Int(hash[offset + 2]) & 0xff) << 8)
            | (Int(hash[offset + 3]) & 0xff)
        let divisor = Int(pow(10.0, Double(digits)))
        let otp = binary % divisor
        return String(format: "%0*d", digits, otp)
    }

    public func remainingSeconds(date: Date = Date()) -> Int {
        guard period > 0 else { return 0 }
        let unix = Int(date.timeIntervalSince1970)
        let remaining = period - (unix % period)
        return remaining == 0 ? period : remaining
    }
}
