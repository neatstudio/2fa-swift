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
- Adds, edits, and deletes 2FA entries.
- Generates standard 6-digit TOTP codes with 30-second refresh.
- Copies codes to the clipboard.
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

The app runs as a menu-bar item named `2fa`. Click it to view codes, add accounts, change groups, or open settings.

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

The verification runner checks Base32 decoding, TOTP test vectors, Go-compatible JSON fields, fractional-second RFC3339 dates, grouped filtering, edits, deletes, and loading the live `~/.2fa/accounts.json` file without printing secrets.

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
