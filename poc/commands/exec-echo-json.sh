#!/usr/bin/env bash
set -euo pipefail

echo "Running codex exec --json 'echo hi'..."
codex exec --json "echo hi"

echo
echo "Resuming last session with 'echo hi again'..."
codex exec --json resume --last "echo hi again"
