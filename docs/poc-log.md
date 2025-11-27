# Codex.nvim PoC Log

Date: 2025-11-27

- Auth: `~/.codex/auth.json` present (ChatGPT login); `OPENAI_API_KEY`/`CODEX_API_KEY` not set in env; `codex-cli 0.63.0` available at `~/.volta/bin/codex`.
- Streaming & exec events: `codex exec --json "echo hi"` emitted `reasoning`, `command_execution`, `agent_message`, `turn.completed`; warnings about D-Bus/compositor appeared in `aggregated_output` but exit code 0. `codex exec --json resume --last "echo hi again"` worked with the same warnings.
- Sandbox/approvals: `codex sandbox linux touch /tmp/codex-poc-sandbox` denied (read-only). `codex sandbox linux --full-auto touch /tmp/codex-poc-sandbox` succeeded; file removed afterward.
- Model override & reasoning: `codex exec --json --model gpt-4o-mini ...` failed (ChatGPT account not allowed) after the CLI printed transient `stream disconnected - retrying` warnings; `--model gpt-5.1-codex` with default config hit unsupported reasoning effort `xhigh`; overriding via `-c model_reasoning_effort="medium"` succeeded (`codex exec --json -c model_reasoning_effort="medium" "echo medium effort"`).
- Structured output: `codex exec --json -c model_reasoning_effort="medium" --output-schema /tmp/codex-schema.json "Return JSON with msg:'ok'"` returned `{"msg":"ok"}` as `agent_message` with streaming events.
- Prompts/execpolicy/MCP: prompts directory contains `review-diff.md`, `review-pr-comments.md`. No `~/.codex/policy` directory. MCP not evaluated (pending/skip).
- MCP decision: Skipped for now (out of initial scope, unstable surface). Documented to revisit only if requested.
