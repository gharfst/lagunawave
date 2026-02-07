#!/usr/bin/env bash
set -euo pipefail

BUNDLE_ID="com.nodogbite.lagunawave"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
"$ROOT_DIR/scripts/build.sh"

# Reset privacy permissions so ad-hoc signed dev builds get fresh prompts
# (not needed for production Developer ID builds where the identity is stable)
tccutil reset Accessibility "$BUNDLE_ID" 2>/dev/null || true
tccutil reset Microphone "$BUNDLE_ID" 2>/dev/null || true

open "$ROOT_DIR/build/LagunaWave.app"
