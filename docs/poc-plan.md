# Codex.nvim PoC Plan

Goal: validate quickly the key capabilities before locking architecture or scaffolding.

Principles
- Keep each probe minimal (one command or small Lua snippet).
- Prefer dry-run/echo modes where possible; avoid persisting secrets.
- Record outcomes to feed back into `PLAN.md` and config defaults.
- Make runs replicable: persist scripts under `poc/commands/` for each probe and log outputs in `docs/poc-log.md`.

Checklist (must-know signals)
- Auth paths
  - ✅ ChatGPT login token present (from Codex CLI) can be read/forwarded by Lua client.
  - ✅ API key flow via `OPENAI_API_KEY`/`CODEX_API_KEY` works (non-interactive).
  - ⚠️ Behavior on missing auth: clear error surfaced, health check detects it.
- Streaming & schema
  - ✅ Responses API streaming parsed incrementally into Neovim buffer.
  - ✅ Structured output equivalent (`--output-schema` style) can be requested and parsed.
  - ⚠️ Backpressure/partial chunk handling verified.
- Model selection & reasoning knobs
  - ✅ Override `model`/`model_provider` per request/config and observe effective model in responses.
  - ✅ Toggle reasoning/verbosity controls (e.g., `model_reasoning_effort`, reasoning summary) and confirm they propagate.
  - ⚠️ Record any provider/model-specific limitations.
- `codex exec --json` events
  - ✅ Spawn `codex exec --json "echo hi"` and parse JSONL events; capture item types and turn boundaries.
  - ✅ Resume handling (`codex exec resume --last`) works or is intentionally unsupported.
  - ⚠️ Failure modes (non-zero exit, malformed JSON) handled gracefully.
- Sandbox/approvals behavior
  - ✅ Detect git repo requirement; confirm `--skip-git-repo-check` impact.
  - ✅ Observe sandbox modes (read-only vs workspace-write) and approval policy effects on tool calls.
  - ✅ Network allowed/blocked as expected per sandbox preset.
- Prompts directory
  - ✅ List and load prompts from `~/.codex/prompts/*.md`; validate placeholder expansion expectations.
  - ✅ Decide whether to surface `/prompts:<name>` equivalents or only listable prompts.
- Execpolicy (optional)
  - ✅ Detect presence of `~/.codex/policy/*.codexpolicy`; note if validation errors are exposed.
  - ⚠️ Decide whether to expose a warning in health check or ignore by default.
- MCP (optional)
  - ✅ Confirm Codex MCP client/server availability; identify minimal hook if we surface it.
  - ⚠️ Skip integration if unstable; document rationale.
- CLI integration (optional)
  - ✅ Launch Codex CLI in a terminal buffer (or tmux/zellij) and keep session attached.
  - ✅ Pipe context (file/selection) into CLI commands; confirm auto-reload or watcher behavior if used.
- Windows note
  - ⚠️ Confirm we will recommend WSL2 and avoid promising native sandbox guarantees.

Execution notes
- Document each probe result in a short log (pass/fail + notes) to be reflected back into `PLAN.md`.
- If a probe is skipped, record the reason (low value, unstable, out of scope).
- Stop PoC once all checklist items have a disposition (pass/fail/skip).

Scripts y resultados (ejecutados)
- Auth: `poc/commands/auth-check.sh` → PASS (auth.json presente; API keys ausentes; codex-cli 0.63.0).
- Streaming & resume: `poc/commands/exec-echo-json.sh` → PASS (eventos JSONL completos, avisos DBus irrelevantes).
- Sandbox: `poc/commands/sandbox-touch.sh` → PASS (read-only bloquea touch; `--full-auto` permite).
- Model/reasoning: `poc/commands/model-reasoning.sh` → PASS (gpt-5.1-codex con `model_reasoning_effort=medium` funciona; otros modelos fallan según cuenta).
- Structured output: `poc/commands/structured-output.sh` → PASS (schema aplicado, respuesta `{"msg":"ok"}`).
- Prompts: listado manual (`~/.codex/prompts/`), sin script dedicado; presentes `review-diff.md`, `review-pr-comments.md`.
- Execpolicy: sin `~/.codex/policy`; no script (N/A).
- MCP: marcado como SKIP (no evaluado).
