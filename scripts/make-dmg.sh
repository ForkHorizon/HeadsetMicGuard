#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

APP_NAME="${APP_NAME:-HeadsetMicGuard}"
BUILD_DIR="${BUILD_DIR:-$ROOT_DIR/build}"
RELEASE_DIR="${RELEASE_DIR:-$BUILD_DIR/release}"
STAGING_DIR="$RELEASE_DIR/dmg-staging"

cd "$ROOT_DIR"

"$SCRIPT_DIR/build-release.sh"

VERSION="$(cat "$RELEASE_DIR/VERSION")"
APP_PATH="$RELEASE_DIR/$APP_NAME.app"
DMG_PATH="$RELEASE_DIR/$APP_NAME-$VERSION.dmg"

if [[ ! -d "$APP_PATH" ]]; then
  echo "error: expected app not found at $APP_PATH" >&2
  exit 1
fi

rm -rf "$STAGING_DIR" "$DMG_PATH"
mkdir -p "$STAGING_DIR"

ditto "$APP_PATH" "$STAGING_DIR/$APP_NAME.app"
ln -s /Applications "$STAGING_DIR/Applications"

hdiutil create \
  -volname "$APP_NAME" \
  -srcfolder "$STAGING_DIR" \
  -ov \
  -format UDZO \
  "$DMG_PATH"

if [[ -n "${SIGN_IDENTITY:-}" ]]; then
  codesign --force --timestamp --sign "$SIGN_IDENTITY" "$DMG_PATH"
fi

if [[ -n "${NOTARY_PROFILE:-}" ]]; then
  xcrun notarytool submit "$DMG_PATH" --keychain-profile "$NOTARY_PROFILE" --wait
  xcrun stapler staple "$DMG_PATH"
elif [[ -n "${APPLE_ID:-}" && -n "${APPLE_TEAM_ID:-}" && -n "${APPLE_APP_SPECIFIC_PASSWORD:-}" ]]; then
  xcrun notarytool submit "$DMG_PATH" \
    --apple-id "$APPLE_ID" \
    --team-id "$APPLE_TEAM_ID" \
    --password "$APPLE_APP_SPECIFIC_PASSWORD" \
    --wait
  xcrun stapler staple "$DMG_PATH"
else
  echo "Notarization skipped. Set NOTARY_PROFILE or APPLE_ID, APPLE_TEAM_ID, and APPLE_APP_SPECIFIC_PASSWORD to notarize."
fi

rm -rf "$STAGING_DIR"

echo "Created $DMG_PATH"
