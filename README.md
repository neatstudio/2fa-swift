# 2fa-swift

Native macOS menu-bar viewer for the [`2fa`](https://github.com/neatstudio/2fa) account file.

`2fa-swift` is a local Swift/AppKit + SwiftUI app that reads and writes the same data file used by the Go CLI version:

```text
~/.2fa/accounts.json
```

It does not start a server and does not expose your codes over the network.

## Features

- Native macOS menu-bar app.
- Shows all TOTP accounts or filters by group.
- Searches by account name, group, or note.
- Adds, edits, and deletes 2FA entries.
- Generates standard 6-digit TOTP codes with 30-second refresh.
- Copies codes to the clipboard and clears unchanged copied codes after 30 seconds.
- Imports, exports, and replaces Go-compatible `accounts.json` files.
- Creates timestamped backups before overwriting existing data.
- Detects damaged JSON and saves a `.damaged.json` backup instead of silently losing data.
- Reuses the existing `~/.2fa/accounts.json` file from the Go version.
- Keeps raw secrets hidden in the UI.
- No `serve` mode, HTTP server, LAN access, or browser UI.

## Requirements

- macOS 13 or newer.
- Existing `~/.2fa/accounts.json`, or create entries from the app.

## Install from Release

1. Download `2fa.app.zip` from the latest GitHub Release.
2. Unzip it.
3. Move `2fa.app` to `/Applications`.
4. Open `2fa.app`.

The app runs as a menu-bar item named `2fa`. Click it to view codes, search, add accounts, change groups, import/export backups, or open settings.

If macOS blocks the app because it is unsigned, open **System Settings → Privacy & Security** and allow it, or run:

```bash
xattr -dr com.apple.quarantine /Applications/2fa.app
open /Applications/2fa.app
```

## Data file

The app reads and writes:

```text
~/.2fa/accounts.json
```

The file format matches the Go version:

```json
{
  "accounts": [
    {
      "name": "github",
      "group": "work",
      "note": "GitHub admin login",
      "secret": "JBSWY3DPEHPK3PXP",
      "created_at": "2026-05-20T05:47:06.201894Z",
      "updated_at": "2026-05-20T05:47:06.201894Z"
    }
  ]
}
```

Notes:

- `name` is required and globally unique.
- Empty `group` becomes `default`.
- Secrets are normalized by removing whitespace and uppercasing.
- The UI does not display raw secrets, but the JSON file contains them for compatibility with the Go CLI.
- Keep `~/.2fa/accounts.json` private; recommended permissions are directory `0700` and file `0600`.

## Backup, import, and recovery

Use **Settings → Export…** to write a copy of your accounts file before moving devices or changing machines.

Use **Settings → Import and Merge…** to add accounts from another compatible JSON file. Duplicate names are rejected so existing secrets are not silently overwritten.

Use **Settings → Replace from File…** to replace the current data with another compatible `accounts.json` file. The app creates a timestamped backup first:

```text
~/.2fa/accounts.YYYYMMDD-HHMMSS-SSS.backup.json
```

If the app cannot decode `~/.2fa/accounts.json`, it leaves the broken file in place and creates:

```text
~/.2fa/accounts.YYYYMMDD-HHMMSS-SSS.damaged.json
```

You can then restore from a known-good backup or export from another device.

## Clipboard behavior

When you copy a TOTP code, the app clears the clipboard after 30 seconds if the clipboard still contains that same code. If you copy something else meanwhile, the app leaves it untouched.

## Build from source

```bash
swift build -c release
```

Run directly during development:

```bash
swift run 2fa
```

Run the compatibility verification runner:

```bash
swift run TwoFAVerify
```

The verification runner checks Base32 decoding, TOTP test vectors, Go-compatible JSON fields, fractional-second RFC3339 dates, backup/recovery behavior, import/export, grouped filtering, edits, deletes, and loading the live `~/.2fa/accounts.json` file without printing secrets.

## Package a local app bundle

```bash
swift build -c release
mkdir -p dist/2fa.app/Contents/MacOS dist/2fa.app/Contents/Resources
cp .build/release/2fa dist/2fa.app/Contents/MacOS/2fa
chmod +x dist/2fa.app/Contents/MacOS/2fa
cp packaging/Info.plist dist/2fa.app/Contents/Info.plist
```

Then open:

```bash
open dist/2fa.app
```
