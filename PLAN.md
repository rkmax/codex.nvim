# Codex.nvim Plan

## Goal
- Build a Neovim plugin that brings Codex capabilities (chat, inline help, code edits) with a UX comparable to modern IDE assistants.
- Follow Neovim ecosystem conventions for installation, configuration, health checks, and testing.

## Scope
- Provide a Lua-based Codex client (no external binaries) that wraps the latest Codex API endpoints.
- Support chat-style interactions and apply-to-buffer edits; explore inline completions as a stretch goal once the API surface is clear.
- Offer commands and keymaps for quick prompts (explain, fix, generate, summarize) with contextual code selection.
- Implement `:checkhealth codex` diagnostics, and Lua APIs consumable by other plugins.
- Optional: terminal-based AI CLI integration (Codex CLI, Claude, Gemini, etc.) with shared prompts and context piping.
- Out of scope for the first iteration: fine-tuning flows, telemetry/analytics, and non-Neovim editors.

## References
- Codex SDK docs: https://developers.openai.com/codex/sdk
- Codex source: https://github.com/openai/codex (for protocol/feature parity)
- Sidekick.nvim: https://github.com/folke/sidekick.nvim (health checks, packaging patterns, testing harness)

## Milestones
1) Research
   - Review Codex API surface (auth, endpoints, streaming, models, rate limits) using SDK docs and source.
   - Extract protocol details from https://github.com/openai/codex to mirror VSCode feature parity.
   - Map Neovim patterns from sidekick.nvim (health checks, configuration defaults, packaging, testing harness).
   - Capture findings in notes and revisit the full plan after each research pass before advancing milestones.
2) Architecture & scaffolding
   - Sketch plugin layout (`lua/codex/...`), setup entrypoint, and default config modules.
   - Define minimal command set and UX flows (chat buffer, floating windows, inline apply).
   - Add initial files: module loader, setup boilerplate, placeholders for commands/UI/client.
3) Lua Codex client
   - Implement HTTP client (likely via `vim.loop`/`plenary.curl`) with auth, retries, streaming parsing.
   - Add request builders for chat/completions/edits; normalize responses for buffers.
   - Gate features by API availability (feature flags/capabilities).
4) Editor UX
   - Commands: `:CodexChat`, `:CodexAsk`, `:CodexFix`, `:CodexExplain`, `:CodexApply`.
   - UI: floating chat window, inline virtual text previews, diff/apply flow for edits.
   - Context capture: selection, filetype, cursor location, workspace signals.
5) AI CLI integration (optional)
   - Terminal wrapper to run Codex CLI or other AI CLIs (Claude, Gemini, Copilot CLI) with context prompts.
   - Multiplexer support (tmux/zellij) and keymaps to toggle/focus/attach sessions.
   - Shared prompt templates for file/selection/diagnostics to mirror sidekick-style workflows.
6) Health, config, and packaging
   - `:checkhealth codex` to validate API key, network, and minimal request.
   - Options: endpoint, model, temperature, timeouts, UI tweaks, logging level.
   - Help docs (`:h codex`), README, and example configs (lazy.nvim, packer).
7) Testing & quality
   - Unit tests with plenary; mock HTTP for determinism.
   - Integration smoke test with a live Codex request (skippable if no key).
   - Linting/formatting (stylua, selene) and CI skeleton (GitHub Actions).

## Risks & open questions
- API specifics may diverge from the public SDK; need to confirm streaming and edit endpoints.
- Authentication/storage strategy (env var vs. config) must avoid persisting secrets.
- Inline completion ergonomics depend on latency; may need caching or prefetching.
- Research is iterative; plan revisions may be needed as API or ecosystem details surface.

## Next steps
- Deep-dive Codex docs/source and sidekick.nvim patterns to lock API/UX assumptions, then update the plan based on findings.
- Refine the plan and milestones with any research-driven adjustments before proceeding.
