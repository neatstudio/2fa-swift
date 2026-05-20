import Foundation
import TwoFACore

enum VerifyError: Error, CustomStringConvertible {
    case failed(String)

    var description: String {
        switch self {
        case .failed(let message): message
        }
    }
}

func expect(_ condition: @autoclosure () throws -> Bool, _ message: String) throws {
    if try !condition() {
        throw VerifyError.failed(message)
    }
}

func expectThrows(_ message: String, _ body: () throws -> Void) throws {
    do {
        try body()
    } catch {
        return
    }
    throw VerifyError.failed(message)
}

func makeRepository() -> AccountRepository {
    let directory = URL(fileURLWithPath: NSTemporaryDirectory())
        .appendingPathComponent(UUID().uuidString, isDirectory: true)
    return AccountRepository(metadataURL: directory.appendingPathComponent("accounts.json"))
}

func runVerification() throws {
    try expect(Base32.normalize("jbsw y3dp\nehpk3pxp") == "JBSWY3DPEHPK3PXP", "Base32 normalization failed")
    try expect(Array(try Base32.decode("JBSWY3DPEHPK3PXP")) == [72, 101, 108, 108, 111, 33, 222, 173, 190, 239], "Base32 decode failed")
    try expectThrows("Invalid Base32 character was accepted") {
        _ = try Base32.decode("ABC1")
    }

    let totp = TOTPService()
    try expect(try totp.code(secret: "JBSWY3DPEHPK3PXP", date: Date(timeIntervalSince1970: 0)).count == 6, "TOTP code length failed")
    let vectorService = TOTPService(period: 30, digits: 8)
    let vectorSecret = "GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ"
    try expect(try vectorService.code(secret: vectorSecret, date: Date(timeIntervalSince1970: 59)) == "94287082", "RFC6238 vector 59 failed")
    try expect(try vectorService.code(secret: vectorSecret, date: Date(timeIntervalSince1970: 1111111109)) == "07081804", "RFC6238 vector 1111111109 failed")
    try expect(try vectorService.code(secret: vectorSecret, date: Date(timeIntervalSince1970: 2000000000)) == "69279037", "RFC6238 vector 2000000000 failed")
    try expect(totp.remainingSeconds(date: Date(timeIntervalSince1970: 0)) == 30, "Remaining at boundary failed")
    try expect(totp.remainingSeconds(date: Date(timeIntervalSince1970: 29)) == 1, "Remaining countdown failed")

    let repository = makeRepository()
    let account = try repository.add(
        name: " github ",
        group: " ",
        note: " admin ",
        secret: "jbsw y3dp ehpk3pxp",
        now: Date(timeIntervalSince1970: 0)
    )
    try expect(account.id == "github", "Account id should match Go-compatible name")
    try expect(account.name == "github", "Name normalization failed")
    try expect(account.group == "default", "Default group normalization failed")
    try expect(account.note == "admin", "Note trimming failed")
    try expect(account.secret == "JBSWY3DPEHPK3PXP", "Secret normalization failed")

    let metadata = String(decoding: try Data(contentsOf: repository.metadataURL), as: UTF8.self)
    try expect(metadata.contains("\"secret\""), "Go-compatible metadata is missing secret field")
    try expect(metadata.contains("JBSWY3DPEHPK3PXP"), "Go-compatible metadata is missing normalized secret")
    try expect(metadata.contains("created_at"), "Go-compatible metadata is missing created_at")
    try expect(metadata.contains("updated_at"), "Go-compatible metadata is missing updated_at")

    let goRepository = makeRepository()
    try FileManager.default.createDirectory(at: goRepository.metadataURL.deletingLastPathComponent(), withIntermediateDirectories: true)
    try """
    {
      "accounts": [
        {
          "name": "temoneyBarriger",
          "group": "seo",
          "note": "gmail 2fa",
          "secret": "jbsw y3dp ehpk3pxp",
          "created_at": "2026-05-20T05:47:06.201894Z",
          "updated_at": "2026-05-20T05:47:06.201894Z"
        }
      ]
    }
    """.data(using: .utf8)!.write(to: goRepository.metadataURL, options: .atomic)
    let goAccounts = try goRepository.load()
    try expect(goAccounts.count == 1, "Go JSON account count failed")
    try expect(goAccounts[0].name == "temoneyBarriger", "Go JSON name decode failed")
    try expect(goAccounts[0].secret == "JBSWY3DPEHPK3PXP", "Go JSON secret normalization failed")
    try expect(try goRepository.displayRows(accounts: goAccounts).count == 1, "Go JSON display row generation failed")

    let liveRepository = AccountRepository.live()
    let liveAccounts = try liveRepository.load()
    print("Live accounts loaded: \(liveAccounts.count)")
    for liveAccount in liveAccounts {
        print("- \(liveAccount.name) [\(liveAccount.group)]")
    }

    try expectThrows("Duplicate name was accepted") {
        _ = try repository.add(name: "github", group: "other", note: "", secret: "JBSWY3DPEHPK3PXP")
    }

    let groupRepository = makeRepository()
    let game = try groupRepository.add(name: "a", group: "game", note: "", secret: "JBSWY3DPEHPK3PXP")
    _ = try groupRepository.add(name: "b", group: "games", note: "", secret: "JBSWY3DPEHPK3PXP")
    try expect(try groupRepository.load().filter { $0.group == "game" }.map(\.id) == [game.id], "Exact group filtering failed")

    let updated = try repository.update(name: account.name, group: "personal", note: "new note", replacementSecret: "")
    try expect(updated.group == "personal", "Update group failed")
    try expect(updated.note == "new note", "Update note failed")
    try expect(updated.secret == "JBSWY3DPEHPK3PXP", "Blank replacement secret changed secret")

    let replacement = try repository.update(name: account.name, group: "personal", note: "new note", replacementSecret: "GEZDGNBVGY3TQOJQ")
    try expect(replacement.secret == "GEZDGNBVGY3TQOJQ", "Replacement secret failed")

    try repository.delete(name: account.name)
    try expect(try repository.load().isEmpty, "Delete metadata failed")
}

do {
    try runVerification()
    print("Verification passed")
} catch {
    fputs("Verification failed: \(error)\n", stderr)
    exit(1)
}
