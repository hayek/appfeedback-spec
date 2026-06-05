#!/usr/bin/env bash
# Copy the canonical conformance fixtures into the Web SDK's test fixtures.
# Override the Web location with APPFEEDBACK_WEB_DIR if not the sibling.
set -euo pipefail
SPEC_DIR="$(cd "$(dirname "$0")/.." && pwd)"
WEB_DIR="${APPFEEDBACK_WEB_DIR:-$SPEC_DIR/../appfeedback-web}"
DEST="$WEB_DIR/packages/core/test/fixtures/conformance"
mkdir -p "$DEST"
cp "$SPEC_DIR/fixtures/format-cases.json" "$DEST/format-cases.json"
cp "$SPEC_DIR/fixtures/parse-cases.json" "$DEST/parse-cases.json"
echo "Synced fixtures → $DEST"
