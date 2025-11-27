# Codex.nvim UX & UI Flows

## Goals
- Keep interactions idiomatic to Neovim (commands, keymaps, floating windows).
- Provide clear entry/exit flows and avoid noisy UI by default.
- Make Codex actions discoverable (chat, explain/fix/apply, prompts) and auditable (exec stream log).

## Entry points
- Commands (core):
  - `:CodexChat` — open chat panel.
  - `:CodexAsk` — quick question with current context (selection/file).
  - `:CodexExplain` — explain selection/file.
  - `:CodexFix` — propose fix for selection/file.
  - `:CodexApply` — run apply-to-buffer flow with diff review.
  - `:CodexPrompt <name>` — run a prompt from `~/.codex/prompts`.
  - `:CodexLog` — open event log panel (exec JSON stream).
- Optional CLI entry:
  - `:CodexExec <prompt>` — run `codex exec --json` in a terminal split and feed log panel.
  - `:CodexExecResume` — resume last exec session.

## Chat UI
- Layout: floating window with two panes:
  - Transcript pane: messages (user/assistant), reasoning snippets inline.
  - Input pane: single-line or small textarea; supports context injection toggles.
- Actions:
  - Submit: `<CR>` in input.
  - Toggle context (selection/file/diagnostics): keybinds (e.g., `<leader>cc` to include selection).
  - Model/sandbox quick pick: command palette or keymap (e.g., `<leader>cm` for model, `<leader>cs` for sandbox preset).
- Exit: close window (`q`/`<Esc>`) or `:bd` on buffer.

## Apply flow
- Trigger: `:CodexApply` or when chat response includes edits.
- UI: diff view (floating or vsplit) showing proposed changes; buffer actions:
  - Apply all: keymap (e.g., `a`).
  - Apply hunk-by-hunk: `n`/`p` to navigate, `enter` to accept hunk.
  - Reject all: `q`/`r`.
- Exit: close diff window(s); if applied, write buffer or leave modified.

## Event log (exec stream)
- Trigger: `:CodexLog` or auto-open when `:CodexExec` runs.
- Layout: split window listing events with timestamps and types.
- Default view: shows `agent_message` and `reasoning`; other types collapsed.
- Keymaps (buffer-local):
  - Toggle categories: `c` (commands), `f` (file changes), `w` (web search), `a` (agent/reasoning always on).
  - Expand/collapse entry: `<CR>` on list item.
  - Jump to exec terminal buffer: `t`.
  - Close log: `q`.
- Exit: close the log buffer/split.

## Prompt runner
- `:CodexPrompt <name> [ARGS]`:
  - Lists prompts if no name given (from `~/.codex/prompts`).
  - Shows description/argument hint if frontmatter available.
  - On select, expands placeholders and sends via chat flow.
- Minimal UI: small popup list; falls back to command-line completion if popup fails.

## Config toggles (discoverable)
- Command to pick model/provider/profile (e.g., `:CodexModelPicker`).
- Command to pick sandbox/approval preset (e.g., `:CodexSandboxPicker`).
- Command to toggle structured output (on/off) for next request.

## Exit flows
- Close any panel with `q`/`<Esc>`; `:CodexStop` can close chat/log windows.
- Exec terminal stays until user closes the terminal buffer.

## Error/edge handling
- If auth missing: health check warns; commands show concise error with pointer to login.
- If model unsupported: surface error in chat/log and suggest default.
- If sandbox blocks action: show message in log/chat; suggest switching preset.
- Keep noisy warnings (e.g., DBus) in exec terminal; summarize status in log panel.
