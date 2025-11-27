#!/usr/bin/env bash
set -euo pipefail

TARGET="/tmp/codex-poc-sandbox"

echo "Attempting read-only sandbox (expected to fail)..."
if codex sandbox linux touch "$TARGET"; then
  echo "Unexpected success in read-only sandbox"
else
  echo "Read-only sandbox blocked touch as expected"
fi

echo "Attempting full-auto sandbox (expected to succeed)..."
codex sandbox linux --full-auto touch "$TARGET"
echo "File created: $TARGET"

rm -f "$TARGET"
echo "Cleanup complete"
