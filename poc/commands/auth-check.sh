#!/usr/bin/env bash
set -euo pipefail

CODEX_HOME="${CODEX_HOME:-$HOME/.codex}"

echo "codex binary: $(command -v codex || echo 'missing')"
echo "codex version: $(codex --version 2>/dev/null || echo 'unavailable')"

if [[ -f "${CODEX_HOME}/auth.json" ]]; then
  echo "auth.json: present at ${CODEX_HOME}/auth.json"
else
  echo "auth.json: missing at ${CODEX_HOME}/auth.json"
fi

if [[ -n "${OPENAI_API_KEY:-}" ]]; then
  echo "OPENAI_API_KEY: set"
else
  echo "OPENAI_API_KEY: missing"
fi

if [[ -n "${CODEX_API_KEY:-}" ]]; then
  echo "CODEX_API_KEY: set"
else
  echo "CODEX_API_KEY: missing"
fi
