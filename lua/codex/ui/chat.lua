local log = require("codex.log")
local ctx = require("codex.context")
local client = require("codex.client.http")

local M = {}

local function create_window()
  local buf = vim.api.nvim_create_buf(false, true)
  local width = math.floor(vim.o.columns * 0.6)
  local height = math.floor(vim.o.lines * 0.6)
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

  vim.api.nvim_buf_set_option(buf, "filetype", "codexchat")
  vim.api.nvim_buf_set_option(buf, "buftype", "nofile")
  vim.api.nvim_buf_set_option(buf, "bufhidden", "wipe")
  vim.api.nvim_buf_set_option(buf, "modifiable", true)

  -- Input prompt at the bottom
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "Codex Chat", string.rep("-", 40), "", "Prompt: ", "", "Response will appear below...", "" })

  vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = buf, silent = true })
  vim.keymap.set("n", "<Esc>", "<cmd>close<cr>", { buffer = buf, silent = true })

  return buf, win
end

local function append(buf, lines)
  if type(lines) == "string" then
    lines = { lines }
  end
  local line_count = vim.api.nvim_buf_line_count(buf)
  vim.api.nvim_buf_set_lines(buf, line_count, line_count, false, lines)
end

local function render_header(buf, prompt, context_data)
  local lines = {
    "Codex Chat",
    string.rep("-", 40),
  }
  if prompt and prompt ~= "" then
    table.insert(lines, "Prompt: " .. prompt)
  end
  if context_data and context_data.filepath and context_data.filepath ~= "" then
    table.insert(lines, "File: " .. context_data.filepath)
  end
  table.insert(lines, "")
  table.insert(lines, "Sending request...")
  table.insert(lines, "")
  append(buf, lines)
end

local function render_result(buf, resp, err)
  if err then
    append(buf, { "Error:", err })
  elseif resp then
    append(buf, { "Response:", resp })
  else
    append(buf, { "No response." })
  end
end

function M.open(opts)
  opts = opts or {}
  local buf = create_window()
  local context_data = ctx.capture({})
  render_header(buf, opts.prompt, context_data)

  vim.schedule(function()
    local resp, err = client.chat(opts.prompt or "", context_data)
    render_result(buf, resp, err)
  end)
end

function M.ask(kind, opts)
  opts = opts or {}
  local prompt = opts.prompt or ""
  local header = ("[%s] %s"):format(kind, prompt)
  M.open({ prompt = header })
end

return M
