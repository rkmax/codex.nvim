local log = require("codex.log")

local M = {}

local function apply_full_buffer(text)
  local bufnr = vim.api.nvim_get_current_buf()
  local lines = vim.split(text, "\n", true)
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
  log.info("Applied Codex edits to buffer.")
end

function M.show(edits)
  if not edits or edits == "" then
    log.warn("No edits to apply.")
    return
  end
  apply_full_buffer(edits)
end

return M
