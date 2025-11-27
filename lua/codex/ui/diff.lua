local log = require("codex.log")

local M = {}

local state = {
  hunks = {},
  idx = 1,
  edits = "",
  bufnr = nil,
  target_buf = nil,
}

local function split_lines(text)
  return vim.split(text, "\n", true)
end

local function apply_full_buffer(bufnr, text)
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, split_lines(text))
  log.info("Applied Codex edits to buffer.")
end

local function parse_hunks(diff_lines)
  local hunks = {}
  for _, line in ipairs(diff_lines) do
    local s_old, l_old, s_new, l_new = line:match("^@@ %-(%d+),(%d+) %+([%d]+),(%d+) @@")
    if s_old then
      table.insert(hunks, {
        start_old = tonumber(s_old),
        len_old = tonumber(l_old),
        start_new = tonumber(s_new),
        len_new = tonumber(l_new),
      })
    end
  end
  return hunks
end

local function apply_hunk(target_buf, new_lines, hunk, offset)
  local start_idx = hunk.start_old + offset - 1
  local end_idx = start_idx + hunk.len_old
  local replacement = {}
  for i = hunk.start_new, hunk.start_new + hunk.len_new - 1 do
    table.insert(replacement, new_lines[i])
  end
  vim.api.nvim_buf_set_lines(target_buf, start_idx, end_idx, false, replacement)
  local delta = hunk.len_new - hunk.len_old
  return offset + delta
end

local function apply_all_hunks(target_buf, hunks, new_lines)
  local offset = 0
  for _, h in ipairs(hunks) do
    offset = apply_hunk(target_buf, new_lines, h, offset)
  end
end

local function highlight_hunk(diff_buf, hunk)
  if not hunk then
    return
  end
  vim.api.nvim_buf_clear_namespace(diff_buf, 0, 0, -1)
  local start = hunk._line_start or 0
  vim.api.nvim_buf_add_highlight(diff_buf, 0, "DiffText", start, 0, -1)
end

local function map_hunks_to_lines(diff_output, hunks)
  local line_no = 0
  local idx = 1
  for _, line in ipairs(diff_output) do
    line_no = line_no + 1
    if line:match("^@@ ") then
      if hunks[idx] then
        hunks[idx]._line_start = line_no - 1
      end
      idx = idx + 1
    end
  end
end

function M.show(edits)
  if not edits or edits == "" then
    log.warn("No edits to apply.")
    return
  end
  local bufnr = vim.api.nvim_get_current_buf()
  local name = vim.api.nvim_buf_get_name(bufnr)

  local current_lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local edit_lines = split_lines(edits)

  local tmpfile = vim.fn.tempname()
  local editfile = vim.fn.tempname()
  vim.fn.writefile(current_lines, tmpfile)
  vim.fn.writefile(edit_lines, editfile)

  local diff_buf = vim.api.nvim_create_buf(false, true)
  local diff_output = vim.fn.systemlist({ "diff", "-u", tmpfile, editfile })
  if #diff_output == 0 then
    diff_output = { "[No differences]" }
  end
  vim.api.nvim_buf_set_lines(diff_buf, 0, -1, false, diff_output)
  vim.api.nvim_buf_set_option(diff_buf, "filetype", "diff")
  vim.api.nvim_buf_set_option(diff_buf, "modifiable", false)

  state.hunks = parse_hunks(diff_output)
  map_hunks_to_lines(diff_output, state.hunks)
  state.idx = 1
  state.edits = edits
  state.target_buf = bufnr
  state.bufnr = diff_buf

  local group = vim.api.nvim_create_augroup("CodexDiff", { clear = true })
  vim.api.nvim_create_autocmd("BufLeave", {
    buffer = diff_buf,
    group = group,
    callback = function()
      if vim.api.nvim_buf_is_valid(diff_buf) then
        vim.api.nvim_buf_delete(diff_buf, { force = true })
      end
  end,
  })

  vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = diff_buf, silent = true })
  vim.keymap.set("n", "a", function()
    apply_full_buffer(bufnr, edits)
    vim.cmd("close")
  end, { buffer = diff_buf, silent = true })

  vim.keymap.set("n", "A", function()
    apply_all_hunks(bufnr, state.hunks, edit_lines)
    vim.cmd("close")
  end, { buffer = diff_buf, silent = true })

  vim.keymap.set("n", "n", function()
    if #state.hunks == 0 then
      return
    end
    state.idx = math.min(state.idx + 1, #state.hunks)
    highlight_hunk(diff_buf, state.hunks[state.idx])
  end, { buffer = diff_buf, silent = true })

  vim.keymap.set("n", "p", function()
    if #state.hunks == 0 then
      return
    end
    state.idx = math.max(state.idx - 1, 1)
    highlight_hunk(diff_buf, state.hunks[state.idx])
  end, { buffer = diff_buf, silent = true })

  vim.keymap.set("n", "h", function()
    if #state.hunks == 0 then
      return
    end
    local offset = 0
    for i = 1, state.idx do
      offset = apply_hunk(bufnr, edit_lines, state.hunks[i], offset)
    end
    vim.cmd("close")
  end, { buffer = diff_buf, silent = true })

  highlight_hunk(diff_buf, state.hunks[state.idx])

  log.info(("Showing Codex edits for %s (a=apply all, A=apply all hunks, h=apply current hunk, n/p navigate, q=close)"):format(name ~= "" and name or "[No Name]"))
end

return M
