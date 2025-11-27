# Codex.nvim Plan

## Goal
- Build a Neovim plugin that brings Codex capabilities (chat, inline help, code edits) with a UX comparable to modern IDE assistants.
- Follow Neovim ecosystem conventions for installation, configuration, health checks, and testing.

## Scope
- Provide a Lua-based Codex client (no external binaries) that wraps the latest Codex API endpoints.
- Support chat-style interactions and apply-to-buffer edits; explore inline completions as a stretch goal once the API surface is clear.
- Offer commands and keymaps for quick prompts (explain, fix, generate, summarize) with contextual code selection.
- Implement `:checkhealth codex` diagnostics, and Lua APIs consumable by other plugins.
- Optional: terminal-based AI CLI integration (Codex CLI, Claude, Gemini, etc.) with shared prompts and context piping, including JSON event streaming from `codex exec` when available.
- Out of scope for the first iteration: fine-tuning flows, telemetry/analytics, and non-Neovim editors.

## References
- Codex SDK docs: https://developers.openai.com/codex/sdk
- Codex source: https://github.com/openai/codex (for protocol/feature parity)
- Sidekick.nvim: https://github.com/folke/sidekick.nvim (health checks, packaging patterns, testing harness)

## Milestones
1) Research
   - Completed: Codex docs/source (auth, sandbox/approvals, exec JSON events, prompts, execpolicy, MCP, config defaults) and sidekick.nvim patterns (health, commands, CLI integration).
   - Keep notes updated; revisit if API surface changes.
2) PoC validation
   - Run a fast proof-of-concept covering all planned capabilities before locking architecture. See `docs/poc-plan.md` for the full checklist and quick experiments.
   - Validate auth paths (ChatGPT login vs API key), streaming, `codex exec --json` event parsing, sandbox/approval effects, prompts directory, execpolicy presence, MCP reachability, and CLI integration ergonomics. Keep probes replicable via `poc/commands/` scripts and log outcomes in `docs/poc-log.md`.
3) Architecture & scaffolding
   - Sketch plugin layout (`lua/codex/...`), setup entrypoint, and default config modules based on PoC results.
   - Define minimal command set and UX flows (chat buffer, floating windows, inline apply) plus how to surface slash-style prompts/custom prompts.
   - Add initial files: module loader, setup boilerplate, placeholders for commands/UI/client, and config defaults (model/provider, sandbox/approvals presets).
4) Lua Codex client
   - Implement HTTP client (likely via `vim.loop`/`plenary.curl`) with auth (ChatGPT login token or API key), retries, and streaming parsing for both responses and `codex exec --json` event schema.
   - Add request builders for chat/completions/edits; normalize responses for buffers; support structured output (`--output-schema` equivalent) when feasible.
   - Respect config-like options (model/provider overrides, sandbox/approval presets, profiles) and gate features via capability flags informed by PoC.
5) Editor UX
   - Commands: `:CodexChat`, `:CodexAsk`, `:CodexFix`, `:CodexExplain`, `:CodexApply`; consider `:CodexPrompt <name>` for custom prompt files.
   - UI: floating chat window, inline virtual text previews, diff/apply flow for edits; optional event log view if parsing `codex exec` JSON.
   - Context capture: selection, filetype, cursor location, workspace signals; allow image attachment path if supported.
6) AI CLI integration (optional)
   - Terminal wrapper to run Codex CLI or other AI CLIs (Claude, Gemini, Copilot CLI) with context prompts and JSON event piping for Codex.
   - Multiplexer support (tmux/zellij) and keymaps to toggle/focus/attach sessions.
   - Shared prompt templates for file/selection/diagnostics to mirror sidekick-style workflows; expose prompt directory resolution (`~/.codex/prompts`).
7) Health, config, and packaging
   - `:checkhealth codex` to validate Neovim version, presence of auth (ChatGPT login or API key), network reachability, git repo requirement (or warn about `--skip-git-repo-check`), optional execpolicy files, and optional tools (curl/plenary/http, tmux/zellij if CLI integration).
   - Options: endpoint/base URL, model/provider, temperature, timeouts, sandbox/approval presets, logging level, prompt directory, profile selection; document Windows caveats (recommend WSL2).
   - Help docs (`:h codex`), README, and example configs (lazy.nvim, packer) plus brief MCP note if supported.
8) Testing & quality
   - Unit tests with plenary; mock HTTP/event streams for determinism.
   - Integration smoke test with a live Codex request (skippable if no key) and optional `codex exec --json` trace parser test.
   - Linting/formatting (stylua, selene) and CI skeleton (GitHub Actions).

## Risks & open questions
- API specifics may diverge from the public SDK; need to confirm streaming and edit endpoints and keep parity with `codex exec` event schema.
- Authentication/storage strategy (env var vs. config) must avoid persisting secrets; ChatGPT login flow inside Neovim may need fallback UX.
- Inline completion ergonomics depend on latency; may need caching or prefetching.
- Windows sandbox gaps exist; likely steer users to WSL2 or warn about reduced guarantees.
- Execpolicy/MCP support may be optional; avoid over-scoping until demand is clear; PoC will confirm feasibility.
- Research is iterative; plan revisions may be needed as API or ecosystem details surface.

## Next steps
- Execute the PoC checklist in `docs/poc-plan.md`; update assumptions based on results.
- Move to architecture & scaffolding with PoC outcomes baked in.
- Decide initial surface for prompts (`~/.codex/prompts`) and exec event parsing; defer MCP/execpolicy unless proven in PoC or requested in config.
