#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="LagunaWave"
BUILD_DIR="$ROOT_DIR/build"
APP_DIR="$BUILD_DIR/${APP_NAME}.app"
ZIP_PATH="$BUILD_DIR/${APP_NAME}.zip"
SHA_PATH="$BUILD_DIR/${APP_NAME}.sha256"

if [ -z "${CODESIGN_IDENTITY:-}" ]; then
  echo "CODESIGN_IDENTITY not set. Example:" >&2
  echo "  export CODESIGN_IDENTITY=\"Developer ID Application: Your Name (TEAMID)\"" >&2
  exit 1
fi

if [ -z "${NOTARYTOOL_PROFILE:-}" ] && ([ -z "${APPLE_ID:-}" ] || [ -z "${APPLE_ID_PASSWORD:-}" ] || [ -z "${TEAM_ID:-}" ]); then
  echo "Set NOTARYTOOL_PROFILE or APPLE_ID, APPLE_ID_PASSWORD, TEAM_ID" >&2
  exit 1
fi

"$ROOT_DIR/scripts/notarize.sh"

shasum -a 256 "$ZIP_PATH" | awk '{print $1}' > "$SHA_PATH"

echo "Release artifacts:"
ls -la "$ZIP_PATH" "$SHA_PATH"
