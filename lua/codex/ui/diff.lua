local log = require("codex.log")

local M = {}

local function apply_full_buffer(bufnr, text)
  local lines = vim.split(text, "\n", true)
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
  log.info("Applied Codex edits to buffer.")
end

function M.show(edits)
  if not edits or edits == "" then
    log.warn("No edits to apply.")
    return
  end
  local bufnr = vim.api.nvim_get_current_buf()
  local name = vim.api.nvim_buf_get_name(bufnr)

  local diff_buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(diff_buf, 0, -1, false, vim.split(edits, "\n", true))
  vim.api.nvim_buf_set_option(diff_buf, "filetype", vim.bo.filetype)

  vim.cmd("vsplit")
  local diff_win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(diff_win, diff_buf)
  vim.api.nvim_win_set_option(diff_win, "number", true)
  vim.api.nvim_win_set_option(diff_win, "relativenumber", true)
  vim.api.nvim_buf_set_option(diff_buf, "modifiable", false)

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

  vim.keymap.set("n", "q", function()
    if vim.api.nvim_win_is_valid(diff_win) then
      vim.api.nvim_win_close(diff_win, true)
    end
  end, { buffer = diff_buf, silent = true })

  vim.keymap.set("n", "a", function()
    apply_full_buffer(bufnr, edits)
    if vim.api.nvim_win_is_valid(diff_win) then
      vim.api.nvim_win_close(diff_win, true)
    end
  end, { buffer = diff_buf, silent = true })

  log.info(("Showing Codex edits for %s (a=apply, q=close)"):format(name ~= "" and name or "[No Name]"))
end

return M
