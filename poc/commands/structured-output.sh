#!/usr/bin/env bash
set -euo pipefail

TMP_SCHEMA="$(mktemp)"
cleanup() { rm -f "$TMP_SCHEMA"; }
trap cleanup EXIT

cat > "$TMP_SCHEMA" <<'EOF'
{
  "type": "object",
  "properties": { "msg": { "type": "string" } },
  "required": ["msg"],
  "additionalProperties": false
}
EOF

echo "Running codex exec with output schema..."
codex exec --json -c model_reasoning_effort="medium" --output-schema "$TMP_SCHEMA" "Return JSON with msg:'ok'"
