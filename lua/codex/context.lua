local M = {}

function M.capture(_opts)
  return {
    selection = nil,
    filetype = vim.bo.filetype,
    filepath = vim.api.nvim_buf_get_name(0),
  }
end

return M
