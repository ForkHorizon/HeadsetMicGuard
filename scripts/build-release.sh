#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

PROJECT="${PROJECT:-HeadsetMicGuard.xcodeproj}"
SCHEME="${SCHEME:-HeadsetMicGuard}"
CONFIGURATION="${CONFIGURATION:-Release}"
BUILD_DIR="${BUILD_DIR:-$ROOT_DIR/build}"
DERIVED_DATA_DIR="${DERIVED_DATA_DIR:-$BUILD_DIR/DerivedData}"
RELEASE_DIR="${RELEASE_DIR:-$BUILD_DIR/release}"
APP_NAME="${APP_NAME:-HeadsetMicGuard}"
ARCHS="${ARCHS:-arm64 x86_64}"

cd "$ROOT_DIR"

mkdir -p "$RELEASE_DIR"

VERSION="$(
  xcodebuild -project "$PROJECT" \
    -scheme "$SCHEME" \
    -configuration "$CONFIGURATION" \
    -destination 'platform=macOS' \
    -showBuildSettings 2>/dev/null \
    | awk -F= '/ MARKETING_VERSION = / { gsub(/^[ \t]+|[ \t]+$/, "", $2); print $2; exit }'
)"

if [[ -z "$VERSION" ]]; then
  VERSION="1.0"
fi

XCODEBUILD_ARGS=(
  -project "$PROJECT"
  -scheme "$SCHEME"
  -configuration "$CONFIGURATION"
  -destination "platform=macOS"
  -derivedDataPath "$DERIVED_DATA_DIR"
  clean build
  ONLY_ACTIVE_ARCH=NO
  ARCHS="$ARCHS"
)

if [[ -n "${SIGN_IDENTITY:-}" ]]; then
  XCODEBUILD_ARGS+=(
    CODE_SIGNING_ALLOWED=YES
    CODE_SIGN_IDENTITY="$SIGN_IDENTITY"
    OTHER_CODE_SIGN_FLAGS="--timestamp"
  )
else
  XCODEBUILD_ARGS+=(CODE_SIGNING_ALLOWED=NO)
fi

xcodebuild "${XCODEBUILD_ARGS[@]}"

BUILT_APP="$DERIVED_DATA_DIR/Build/Products/$CONFIGURATION/$APP_NAME.app"
RELEASE_APP="$RELEASE_DIR/$APP_NAME.app"

if [[ ! -d "$BUILT_APP" ]]; then
  echo "error: expected app not found at $BUILT_APP" >&2
  exit 1
fi

rm -rf "$RELEASE_APP"
ditto "$BUILT_APP" "$RELEASE_APP"

echo "Built $RELEASE_APP"
echo "$VERSION" > "$RELEASE_DIR/VERSION"
