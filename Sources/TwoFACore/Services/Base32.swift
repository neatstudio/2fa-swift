import Foundation

public enum Base32Error: LocalizedError, Equatable {
    case emptySecret
    case invalidCharacter(Character)
    case invalidPadding

    public var errorDescription: String? {
        switch self {
        case .emptySecret:
            return "Secret is required."
        case .invalidCharacter(let character):
            return "Secret contains invalid Base32 character: \(character)"
        case .invalidPadding:
            return "Secret contains invalid Base32 padding."
        }
    }
}

public enum Base32 {
    private static let alphabet: [Character: UInt8] = {
        var values: [Character: UInt8] = [:]
        for (index, character) in "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567".enumerated() {
            values[character] = UInt8(index)
        }
        return values
    }()

    public static func normalize(_ secret: String) -> String {
        secret
            .filter { !$0.isWhitespace }
            .map { String($0).uppercased() }
            .joined()
    }

    public static func decode(_ secret: String) throws -> Data {
        let normalized = normalize(secret).trimmingCharacters(in: CharacterSet(charactersIn: "="))
        guard !normalized.isEmpty else {
            throw Base32Error.emptySecret
        }
        guard ![1, 3, 6].contains(normalized.count % 8) else {
            throw Base32Error.invalidPadding
        }

        var buffer = 0
        var bitsLeft = 0
        var bytes: [UInt8] = []

        for character in normalized {
            guard let value = alphabet[character] else {
                throw Base32Error.invalidCharacter(character)
            }
            buffer = (buffer << 5) | Int(value)
            bitsLeft += 5

            if bitsLeft >= 8 {
                bytes.append(UInt8((buffer >> (bitsLeft - 8)) & 0xff))
                bitsLeft -= 8
            }
        }

        if bitsLeft > 0 && (buffer & ((1 << bitsLeft) - 1)) != 0 {
            throw Base32Error.invalidPadding
        }

        return Data(bytes)
    }
}
