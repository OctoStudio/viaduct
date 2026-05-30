# Viaduct

Viaduct is a macOS menu bar app for managing SSH tunnels.

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
