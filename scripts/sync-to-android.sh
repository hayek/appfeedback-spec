#!/usr/bin/env bash
# Copy the canonical conformance fixtures into the Android SDK's test resources.
# Override the Android location with APPFEEDBACK_ANDROID_DIR if not the sibling.
set -euo pipefail
SPEC_DIR="$(cd "$(dirname "$0")/.." && pwd)"
ANDROID_DIR="${APPFEEDBACK_ANDROID_DIR:-$SPEC_DIR/../appfeedback-android}"
DEST="$ANDROID_DIR/src/test/resources/conformance"
mkdir -p "$DEST"
cp "$SPEC_DIR/fixtures/format-cases.json" "$DEST/format-cases.json"
cp "$SPEC_DIR/fixtures/parse-cases.json" "$DEST/parse-cases.json"
echo "Synced fixtures → $DEST"
