local log = require("codex.log")
local ctx = require("codex.context")
local client = require("codex.client.http")
local diff = require("codex.ui.diff")
local state = require("codex.state")

local M = {}

local function create_window()
  local buf = vim.api.nvim_create_buf(false, true)
  local width = math.floor(vim.o.columns * 0.7)
  local height = math.floor(vim.o.lines * 0.7)
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
  vim.api.nvim_buf_call(buf, function()
    vim.cmd("normal! G")
  end)
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

local function run_chat(prompt, transcript, context_data)
  local buf = create_window()
  local context_data = context_data or ctx.capture({})
  render_header(buf, prompt, context_data)

  if transcript then
    for _, msg in ipairs(transcript) do
      append(buf, { ("%s: %s"):format(msg.role, msg.content) })
    end
    append(buf, { "" })
  end

  state.add_message("user", prompt or "")
  local assistant_text = {}
  append(buf, { "Assistant:", "" })

  client.chat_stream(prompt or "", context_data, {
    on_message = function(chunk)
      if chunk and chunk ~= "" then
        append(buf, { chunk })
        table.insert(assistant_text, chunk)
      end
    end,
    on_error = function(err)
      append(buf, { "Error:", err })
    end,
    on_complete = function()
      append(buf, { "", "[Done]" })
      local full = table.concat(assistant_text, "")
      if full ~= "" then
        state.add_message("assistant", full)
      end
    end,
  })
end

function M.open(opts)
  opts = opts or {}
  local prompt = opts.prompt
  local context_data = ctx.capture({})
  if not prompt or prompt == "" then
    vim.ui.input({ prompt = "Codex prompt: " }, function(input)
      if not input or input == "" then
        log.warn("Empty prompt; aborting.")
        return
      end
      run_chat(input, state.get_transcript(), context_data)
    end)
    return
  end

  run_chat(prompt, state.get_transcript(), context_data)
end

function M.ask(kind, opts)
  opts = opts or {}
  local context_data = ctx.capture({})
  local prompt = opts.prompt or ""
  if context_data.selection and context_data.selection ~= "" then
    prompt = prompt .. "\n\nSelected code:\n" .. context_data.selection
  end
  if prompt == "" then
    vim.ui.input({ prompt = ("Codex %s: "):format(kind) }, function(input)
      if not input or input == "" then
        log.warn("Empty prompt; aborting.")
        return
      end
      run_chat(("[%s] %s"):format(kind, input), state.get_transcript(), context_data)
    end)
    return
  end

  run_chat(("[%s] %s"):format(kind, prompt), state.get_transcript(), context_data)
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
      state.add_message("user", input)
      state.add_message("assistant", resp or "")
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
  state.add_message("user", prompt)
  state.add_message("assistant", resp or "")
end

return M
