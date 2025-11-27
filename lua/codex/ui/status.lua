local M = {}

local state = {
  buf = nil,
  win = nil,
  events = {},
  filters = {
    commands = false,
    file_changes = false,
    web = false,
  },
}

local function should_show(event)
  if not event or not event.kind then
    return false
  end
  if event.kind == "agent_message" or event.kind == "reasoning" then
    return true
  end
  if event.kind == "command_execution" and state.filters.commands then
    return true
  end
  if event.kind == "file_change" and state.filters.file_changes then
    return true
  end
  if event.kind == "web_search" and state.filters.web then
    return true
  end
  return false
end

local function render()
  if not state.buf or not vim.api.nvim_buf_is_valid(state.buf) then
    return
  end
  vim.api.nvim_buf_set_option(state.buf, "modifiable", true)
  local lines = { "Codex Event Log", string.rep("-", 40) }
  table.insert(lines, ("Show commands: %s | file changes: %s | web: %s"):format(
    tostring(state.filters.commands),
    tostring(state.filters.file_changes),
    tostring(state.filters.web)
  ))
  table.insert(lines, "Keymaps: c=toggle commands, f=toggle file changes, w=toggle web, q=close")
  table.insert(lines, "")
  for _, ev in ipairs(state.events) do
    if should_show(ev) then
      local line = ("%s: %s"):format(ev.kind, ev.text or ev.command or "")
      table.insert(lines, line)
    end
  end
  vim.api.nvim_buf_set_lines(state.buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(state.buf, "modifiable", false)
end

local function toggle(kind)
  if kind == "commands" then
    state.filters.commands = not state.filters.commands
  elseif kind == "file_changes" then
    state.filters.file_changes = not state.filters.file_changes
  elseif kind == "web" then
    state.filters.web = not state.filters.web
  end
  render()
end

local function create_window()
  local buf = vim.api.nvim_create_buf(false, true)
  local width = math.floor(vim.o.columns * 0.5)
  local height = math.floor(vim.o.lines * 0.4)
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)

  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    style = "minimal",
    border = "single",
    width = width,
    height = height,
    row = row,
    col = col,
  })

  vim.api.nvim_buf_set_option(buf, "filetype", "codexlog")
  vim.api.nvim_buf_set_option(buf, "buftype", "nofile")
  vim.api.nvim_buf_set_option(buf, "bufhidden", "wipe")
  vim.api.nvim_buf_set_option(buf, "modifiable", false)

  vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = buf, silent = true })
  vim.keymap.set("n", "c", function()
    toggle("commands")
  end, { buffer = buf, silent = true })
  vim.keymap.set("n", "f", function()
    toggle("file_changes")
  end, { buffer = buf, silent = true })
  vim.keymap.set("n", "w", function()
    toggle("web")
  end, { buffer = buf, silent = true })

  return buf, win
end

function M.open()
  state.buf, state.win = create_window()
  render()
end

function M.append_event(event)
  table.insert(state.events, event)
  render()
end

return M
