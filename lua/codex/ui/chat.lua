local log = require("codex.log")
local ctx = require("codex.context")
local client = require("codex.client.http")
local diff = require("codex.ui.diff")

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
  append(buf, {
    "Codex Chat",
    string.rep("-", 40),
  })
  if prompt and prompt ~= "" then
    append(buf, { "User:", prompt, "" })
  end
  if context_data and context_data.filepath and context_data.filepath ~= "" then
    append(buf, { ("File: %s"):format(context_data.filepath), "" })
  end
  append(buf, { "Waiting for response...", "" })
end

local function render_result(buf, resp, err)
  if err then
    append(buf, { "Error:", err })
  elseif resp then
    append(buf, { "Assistant:", resp })
  else
    append(buf, { "No response." })
  end
end

local function run_chat(prompt, transcript)
  local buf = create_window()
  local context_data = ctx.capture({})
  render_header(buf, prompt, context_data)

  if transcript then
    for _, msg in ipairs(transcript) do
      append(buf, { ("%s: %s"):format(msg.role, msg.content) })
    end
    append(buf, { "" })
  end

  vim.schedule(function()
    local resp, err = client.chat(prompt or "", context_data)
    render_result(buf, resp, err)
  end)
end

function M.open(opts)
  opts = opts or {}
  local prompt = opts.prompt
  if not prompt or prompt == "" then
    vim.ui.input({ prompt = "Codex prompt: " }, function(input)
      if not input or input == "" then
        log.warn("Empty prompt; aborting.")
        return
      end
      run_chat(input)
    end)
    return
  end

  run_chat(prompt, opts.transcript)
end

function M.ask(kind, opts)
  opts = opts or {}
  local prompt = opts.prompt or ""
  if prompt == "" then
    vim.ui.input({ prompt = ("Codex %s: "):format(kind) }, function(input)
      if not input or input == "" then
        log.warn("Empty prompt; aborting.")
        return
      end
      run_chat(("[%s] %s"):format(kind, input), opts.transcript)
    end)
    return
  end

  run_chat(("[%s] %s"):format(kind, prompt), opts.transcript)
end

function M.apply(opts)
  opts = opts or {}
  local prompt = opts.prompt or ""
  if prompt == "" then
    vim.ui.input({ prompt = "Codex apply prompt: " }, function(input)
      if not input or input == "" then
        log.warn("Empty prompt; aborting.")
        return
      end
      local ctx_data = ctx.capture({})
      local resp, err = client.edits(input, ctx_data)
      if err then
        log.error(err)
        return
      end
      diff.show(resp)
    end)
    return
  end

  local ctx_data = ctx.capture({})
  local resp, err = client.edits(prompt, ctx_data)
  if err then
    log.error(err)
    return
  end
  diff.show(resp)
end

return M
