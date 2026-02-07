#!/usr/bin/env bash
set -euo pipefail

APP_NAME="LagunaWave"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_APP="$ROOT_DIR/build/${APP_NAME}.app"
DEST="/Applications/${APP_NAME}.app"

if [ -z "${CODESIGN_IDENTITY:-}" ]; then
  AUTO_IDENTITY="$(security find-identity -p codesigning -v 2>/dev/null | awk '/Developer ID Application/ {print $2; exit}')"
  if [ -n "$AUTO_IDENTITY" ]; then
    export CODESIGN_IDENTITY="$AUTO_IDENTITY"
    echo "Using Developer ID identity: $CODESIGN_IDENTITY"
  fi
fi

"$ROOT_DIR/scripts/build.sh"

if [ ! -d "$BUILD_APP" ]; then
  echo "Build app not found: $BUILD_APP" >&2
  exit 1
fi

sudo rm -rf "$DEST"
sudo ditto "$BUILD_APP" "$DEST"
sudo xattr -dr com.apple.quarantine "$DEST" || true
sudo codesign --verify --deep --strict "$DEST" || true

echo "Installed $DEST"
