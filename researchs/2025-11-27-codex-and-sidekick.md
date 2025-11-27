Goal
- Summarize Codex CLI/SDK capabilities (auth, config, streaming, model providers) and sidekick.nvim patterns to guide the Neovim plugin architecture and health checks.

Plan
- Review Codex docs/source for authentication modes, configuration surface, and streaming interfaces.
- Inspect the Codex SDK workflow (threads, run/runStreamed, structured output, working directory expectations).
- Analyze sidekick.nvim defaults for CLI integration, health checks, commands, and prompts to reuse proven Neovim patterns.

Findings
- Codex CLI distributes via npm/Homebrew, supports ChatGPT sign-in or API key, persists config in `~/.codex/config.toml`, and documents MCP, execpolicy, and sandbox/approval concepts; login guidance and config references are in the README (source: https://raw.githubusercontent.com/openai/codex/main/README.md).
- Feature flags and config: `config.toml` and `--config` accept TOML values; `[features]` toggles tools like `apply_patch_freeform`, `unified_exec`, `web_search_request`; model selection defaults to Codex-tier models but can be overridden; `model_providers` supports custom providers (OpenAI chat/responses wire APIs, Ollama, Mistral) with env-based auth, headers, query params, and per-provider retries/timeouts (source: https://raw.githubusercontent.com/openai/codex/main/docs/config.md).
- SDK workflow: `@openai/codex-sdk` spawns the Codex CLI and exchanges JSONL events; `startThread().run()` buffers events, while `runStreamed()` yields structured events (`item.completed`, `turn.completed`); supports output schemas (JSON/Zod), image attachments, resume via `resumeThread()` from `~/.codex/sessions`, working directory overrides, and `skipGitRepoCheck`; environment can be controlled via constructor `env` (source: https://raw.githubusercontent.com/openai/codex/main/sdk/typescript/README.md).
- Sidekick.nvim config patterns: defaults include CLI integration with a `tools` map (Codex command defaults to `codex --enable web_search_request`), multiplexing options (`tmux`/`zellij`), context/prompt templates for common tasks, UI/keymaps for CLI windows, and NES settings (source: https://raw.githubusercontent.com/folke/sidekick.nvim/main/lua/sidekick/config.lua).
- Sidekick.nvim health checks: `:checkhealth sidekick` validates Neovim >= 0.11.2, Copilot LSP enabled and status handler attached, warns on multiple LSPs, checks `autoread`, mux binaries (`tmux`/`zellij`), `ps`/`lsof`, and whether each configured CLI tool is executable (source: https://raw.githubusercontent.com/folke/sidekick.nvim/main/lua/sidekick/health.lua).
- Commands pattern: `:Sidekick <module> <command>` dispatches to Lua modules (`nes`, `cli`, `debug`); args parsed from trailing Lua-like tables, restoring visual selections when needed (source: https://raw.githubusercontent.com/folke/sidekick.nvim/main/lua/sidekick/commands.lua).

Conclusions/Next actions
- Codex integration should expose model/provider config (including custom base URLs and feature flags) and allow streaming consumption similar to `runStreamed`, with structured events surfaced to Neovim UI.
- Auth UX needs dual support: ChatGPT-login (if feasible in Neovim) and API-key fallback; default to env vars and avoid persisting secrets.
- Health check should mirror sidekick patterns: validate Neovim version, dependency binaries (curl/plenary/http), presence of API key or login token, and optionally detect multiplexer/buffer watch settings if we add CLI passthrough.
- Adopt sidekick’s CLI/prompt patterns where relevant (prompt templates for explain/fix/review, tool registry, mux options) while tailoring commands (`:CodexChat`, `:CodexApply`, etc.) to our scope.
- Next up: update the project plan with these research-driven assumptions and design the initial Lua client scaffolding and health check outline.
