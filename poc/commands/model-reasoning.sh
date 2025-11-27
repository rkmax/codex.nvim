#!/usr/bin/env bash
set -euo pipefail

echo "Running codex exec with model gpt-5.1-codex and reasoning effort=medium..."
codex exec --json -c model_reasoning_effort="medium" --model gpt-5.1-codex "echo medium effort"
