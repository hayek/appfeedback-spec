#!/usr/bin/env bash
# Copy the canonical conformance fixtures into the Swift SDK's test resources.
# Run after editing anything in ../fixtures. Override the SDK location with
# APPFEEDBACK_SWIFT_DIR if it is not the sibling ../AppFeedbackSDK.
set -euo pipefail
SPEC_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SWIFT_DIR="${APPFEEDBACK_SWIFT_DIR:-$SPEC_DIR/../AppFeedbackSDK}"
DEST="$SWIFT_DIR/Tests/AppFeedbackCoreTests/Fixtures/conformance"
mkdir -p "$DEST"
cp "$SPEC_DIR/fixtures/format-cases.json" "$DEST/format-cases.json"
cp "$SPEC_DIR/fixtures/parse-cases.json" "$DEST/parse-cases.json"
echo "Synced fixtures → $DEST"
