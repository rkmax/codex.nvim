# Codex.nvim Architecture Proposal

## Objectives
- Provide chat, inline help, and apply-to-buffer edits via Codex without relying on external binaries.
- Expose fast toggles for model/provider selection, reasoning knobs, sandbox/approval presets, and structured output.
- Keep UX idiomatic to Neovim (commands, floating windows, health checks, optional CLI integration).

## Constraints & assumptions (from research/PoC)
- Auth: ChatGPT login token from `~/.codex/auth.json` available; API keys optional but not required in CLI flows.
- Models: ChatGPT accounts cannot use `gpt-4o-mini`; default `gpt-5.1-codex` works with `model_reasoning_effort` in `low/medium/high`.
- Structured output: `--output-schema` style is available; streaming JSON events from `codex exec --json` are stable.
- Sandbox: read-only blocks writes; `--full-auto` allows workspace writes; respect git requirement or warn if `--skip-git-repo-check` is needed.
- Platform: recommend WSL2 on Windows; do not promise native sandbox guarantees.
- MCP/execpolicy: optional; skip by default unless configured.

## Module layout (Lua)
- `lua/codex/init.lua`: setup entrypoint; merges user config; registers commands.
- `lua/codex/config.lua`: defaults (model/provider, reasoning effort, sandbox/approval presets, timeouts, prompt dir, logging).
- `lua/codex/client/http.lua`: HTTP wrapper (plenary.curl or vim.loop) for chat/edits; handles auth headers/tokens, retries, streaming parser, structured output.
- `lua/codex/client/exec.lua` (optional): spawn `codex exec --json`; parse JSONL events (thread/turn/item) for CLI integration view.
- `lua/codex/commands.lua`: implements `:CodexChat`, `:CodexAsk`, `:CodexFix`, `:CodexExplain`, `:CodexApply`, `:CodexPrompt`.
- `lua/codex/ui/`:
  - `chat.lua`: floating window/chat buffer, streaming appender, markdown rendering.
  - `diff.lua`: diff/apply flow for edits.
  - `status.lua`: optional event log (if exec JSON is consumed) and sandbox/model indicators.
- `lua/codex/context.lua`: capture selection/filetype/cursor/workspace signals; optional image attachment path handling.
- `lua/codex/prompts.lua`: load prompts from `~/.codex/prompts/*.md`, expand placeholders, list in `:CodexPrompt`.
- `lua/codex/health.lua`: `:checkhealth codex` (Neovim version, auth presence, network check, git repo, optional execpolicy/prompt dir, tmux/zellij if CLI enabled).
- `lua/codex/log.lua`: thin logger (levels), optional file output.

## Config surface
- Core: `model`, `model_provider`, `profile`, `reasoning_effort` (`low|medium|high`), verbosity toggle if exposed by provider.
- Sandbox/approvals: map to presets (`read-only`, `workspace-write`, `danger-full-access`; approvals `on-request`, `never`, etc.); allow per-command override.
- Timeouts/retries: HTTP and streaming idle timeouts; max retries for exec events.
- Prompts: prompt directory path, include/exclude list.
- UI: floating window options (size, border), diff styling, virtual text toggle, log panel toggle.
- CLI integration (optional): enable flag, command template (`codex --enable web_search_request` etc.), mux backend (`tmux`/`zellij`), auto-attach settings.

## Command flows
- Chat (`:CodexChat`): open chat UI; send context (selection/file metadata); stream assistant tokens; support structured output option.
- Ask/Explain/Fix/Apply: build prompts from context, call client, render response or diff for apply-to-buffer.
- Prompt (`:CodexPrompt <name>`): load prompt file, expand args, send via chat flow.
- Exec (optional): run `codex exec --json <prompt>` in terminal buffer; parse events for log view; allow resume `--last`.

## Health checks
- Neovim version >= required; `plenary`/`curl` availability.
- Auth present (`~/.codex/auth.json` or env key for exec mode); network reachability to provider base URL.
- Git repo detection; warn if absent and suggest `--skip-git-repo-check` option.
- Sandbox preset detection; note platform caveats (Windows).
- Optional: presence of prompts dir, execpolicy dir, tmux/zellij binaries if CLI integration enabled.

## Testing
- Unit: client request builders, streaming parsers (HTTP and exec JSONL), prompt loader/placeholder expansion.
- Integration (opt-in): live Codex call smoke test, structured output roundtrip.
- Lua lint/format: stylua, selene; CI workflow stub.

## Open questions
- Do we expose MCP/execpolicy toggles in setup, or gate behind explicit opts?
- How much of `codex exec` event stream should surface in UI vs terminal-only?
- Do we support image attachment end-to-end in chat flow initially or defer?
