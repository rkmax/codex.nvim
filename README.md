# Codex.nvim

Neovim plugin to chat with Codex, apply AI edits, run prompts, and view exec logs.

## Status
Early scaffold: streaming chat works, prompts load, exec log streams JSON, apply replaces buffer in a diff pane. Diff hunks/markdown polish/persistence are future work.

## Installation
With `lazy.nvim`:

```lua
{
  "yourname/codex.nvim",
  config = function()
    require("codex").setup({
      -- optional overrides
      -- model = "gpt-5.1-codex",
      -- cli = { enabled = true, command = "codex", args = { "--json" } },
    })
  end,
}
```

Requirements: Neovim 0.9+, `plenary.curl`, Codex auth (`~/.codex/auth.json` or env key), optional `codex` CLI for exec log.

## Commands
- `:CodexChat [prompt]` open chat (prompts via `vim.ui.input` if omitted).
- `:CodexAsk|Explain|Fix [prompt]` use selection/file context; streams response.
- `:CodexApply [prompt]` shows edits in vsplit, `a` to apply, `q` to close.
- `:CodexPrompt <name> [ARGS]` run prompt from `~/.codex/prompts/*.md` (`$ARGUMENTS` expands).
- `:CodexLog` open exec event log; `c/f/w` toggle commands/files/web; `q` close.
- `:CodexExec <prompt>` runs `codex exec --json` (requires `cli.enabled=true`).
- `:CodexExecResume` resume last exec session.
- `:CodexHealth` run health checks.

## Current behavior
- Chat streams via SSE; selection is appended to prompt for ask/explain/fix.
- Transcript kept in-memory per session; not persisted.
- Apply flow replaces the entire buffer; no hunk-level apply yet.
- Exec log shows agent/commands/file changes/web search with filters.

## Config (defaults)
See `lua/codex/config.lua`:
- `model = "gpt-5.1-codex"`, `model_provider = "openai"`, `reasoning_effort = "medium"`.
- `base_url = "https://api.openai.com/v1"`, `sandbox_mode = "read-only"`, `approval_policy = "on-request"`.
- `prompt_dir = "~/.codex/prompts"`, `cli = { enabled = false, command = "codex", args = { "--json" } }`.
- UI borders/sizes and log filters configurable.

## Roadmap (short)
- Diff hunk navigation/apply.
- Markdown/scroll polish for chat/log.
- Better error surfacing and transcript persistence.

## License
MIT
