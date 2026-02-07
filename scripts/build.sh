#!/usr/bin/env bash
set -euo pipefail

APP_NAME="LagunaWave"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="$ROOT_DIR/build"
APP_DIR="$BUILD_DIR/${APP_NAME}.app"
BIN_DIR="$APP_DIR/Contents/MacOS"
RES_DIR="$APP_DIR/Contents/Resources"
PLIST="$ROOT_DIR/Resources/Info.plist"
ENTITLEMENTS="$ROOT_DIR/Resources/Entitlements.plist"
BIN_SRC="$ROOT_DIR/.build/release/$APP_NAME"

swift build -c release

if [ ! -f "$BIN_SRC" ]; then
  echo "Build output not found: $BIN_SRC" >&2
  exit 1
fi

rm -rf "$APP_DIR"
mkdir -p "$BIN_DIR" "$RES_DIR"

cp "$BIN_SRC" "$BIN_DIR/$APP_NAME"

cp "$PLIST" "$APP_DIR/Contents/Info.plist"

if [ -f "$ROOT_DIR/Resources/AppIcon.icns" ]; then
  cp "$ROOT_DIR/Resources/AppIcon.icns" "$APP_DIR/Contents/Resources/AppIcon.icns"
fi

# Stage to a temp directory for signing to avoid file-provider extended
# attribute contamination (iCloud Drive, Dropbox, etc. re-add xattrs
# immediately, which breaks codesign).
STAGE_DIR=$(mktemp -d)
STAGE_APP="$STAGE_DIR/${APP_NAME}.app"
trap 'rm -rf "$STAGE_DIR"' EXIT
ditto "$APP_DIR" "$STAGE_APP"
xattr -cr "$STAGE_APP"

if [ -z "${CODESIGN_IDENTITY:-}" ]; then
  echo "Signing: ad-hoc"
  codesign --force --deep --sign - "$STAGE_APP"
else
  echo "Signing: $CODESIGN_IDENTITY"
  if [ -f "$ENTITLEMENTS" ]; then
    codesign --force --deep --options runtime --timestamp --entitlements "$ENTITLEMENTS" --sign "$CODESIGN_IDENTITY" "$STAGE_APP"
  else
    codesign --force --deep --options runtime --timestamp --sign "$CODESIGN_IDENTITY" "$STAGE_APP"
  fi
fi

codesign --verify --deep --strict "$STAGE_APP"
echo "Signature verified"

rm -rf "$APP_DIR"
ditto "$STAGE_APP" "$APP_DIR"

echo "Built $APP_DIR"
