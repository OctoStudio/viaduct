# Viaduct

Viaduct is a native macOS menu bar app for creating, monitoring, and reconnecting SSH tunnels.

It wraps the system `ssh` client in a small SwiftUI interface, so tunnel configuration stays visible and repeatable without replacing the SSH tooling already on macOS.

## Features

- Local, remote, and dynamic SOCKS tunnel definitions
- Menu bar controls for connecting, stopping, and viewing tunnel status
- Main window for editing tunnel details, tags, connection settings, and advanced SSH options
- Auto-connect support for selected tunnels
- Reconnect handling for failed tunnels, network changes, and sleep/wake events
- Support for system SSH agent and 1Password SSH agent socket configuration
- Connection activity log and generated command preview
- Local persistence using SQLite through GRDB

## Requirements

- macOS 14 or newer
- Xcode 16 or newer
- Swift 5.10
- XcodeGen, if you need to regenerate the Xcode project from `project.yml`

## Getting Started

Clone the repository and open the generated Xcode project:

```sh
git clone <repo-url>
cd Viaduct
open Viaduct.xcodeproj
```

Build and run the `Viaduct` scheme from Xcode.

If you modify `project.yml`, regenerate the project with:

```sh
xcodegen generate
```

## Testing

Run the test suite from Xcode, or from the command line:

```sh
xcodebuild test \
  -project Viaduct.xcodeproj \
  -scheme Viaduct \
  -destination 'platform=macOS'
```

The current tests cover SSH argument generation and reconnect backoff behavior.

## Release Packaging

Create a local Release build and package it as a zip and DMG:

```sh
Scripts/package-release.sh
```

Artifacts are written to `dist/`:

- `Viaduct-1.0-ad-hoc.zip`
- `Viaduct-1.0-ad-hoc.dmg`

The script uses ad-hoc signing so it can run on machines without a Developer ID certificate. For public distribution, sign with a Developer ID Application certificate and notarize the exported app before shipping.

Useful verification commands:

```sh
codesign --verify --deep --strict --verbose=2 /path/to/Viaduct.app
spctl --assess --type execute --verbose /path/to/Viaduct.app
```

## Project Layout

- `Sources/Viaduct/App`: app lifecycle, settings, and window management
- `Sources/Viaduct/Tunnel`: SSH command construction, process lifecycle, and reconnect policy
- `Sources/Viaduct/Persistence`: database setup and repository access
- `Sources/Viaduct/UI`: menu bar, main window, editor, and shared UI components
- `Tests/ViaductTests`: unit tests
- `Scripts`: local build and packaging helpers

## Contributing

Issues and pull requests are welcome. Please keep changes focused, include tests for behavior changes, and verify the app builds before submitting.

## License

Viaduct is available under the MIT License. See [LICENSE](LICENSE) for details.
