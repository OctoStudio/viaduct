#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="Viaduct"
SCHEME="Viaduct"
CONFIGURATION="Release"
VERSION="${VIADUCT_VERSION:-1.0.1}"
DERIVED_DATA="${VIADUCT_DERIVED_DATA:-/private/tmp/ViaductReleaseDerivedData}"
PACKAGE_DIR="${VIADUCT_PACKAGE_DIR:-/private/tmp/ViaductPackages}"
DIST_DIR="${ROOT_DIR}/dist"
APP_PATH="${DERIVED_DATA}/Build/Products/${CONFIGURATION}/${APP_NAME}.app"
ZIP_PATH="${DIST_DIR}/${APP_NAME}-${VERSION}-ad-hoc.zip"
DMG_PATH="${DIST_DIR}/${APP_NAME}-${VERSION}-ad-hoc.dmg"

mkdir -p "${DIST_DIR}"

xcodebuild \
  -project "${ROOT_DIR}/${APP_NAME}.xcodeproj" \
  -scheme "${SCHEME}" \
  -configuration "${CONFIGURATION}" \
  -derivedDataPath "${DERIVED_DATA}" \
  -clonedSourcePackagesDirPath "${PACKAGE_DIR}" \
  CODE_SIGN_STYLE=Manual \
  CODE_SIGN_IDENTITY=- \
  build

rm -f "${ZIP_PATH}" "${DMG_PATH}"
ditto -c -k --sequesterRsrc --keepParent "${APP_PATH}" "${ZIP_PATH}"
hdiutil create -volname "${APP_NAME}" -srcfolder "${APP_PATH}" -format UDZO "${DMG_PATH}"

codesign --verify --deep --strict --verbose=2 "${APP_PATH}"

printf '\nCreated release artifacts:\n'
ls -lh "${ZIP_PATH}" "${DMG_PATH}"

printf '\nSigning note: this script creates an ad-hoc signed build. Use Developer ID signing and notarization for public distribution.\n'
