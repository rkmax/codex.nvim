local M = {}

local function get_selection()
  local mode = vim.fn.mode()
  if mode ~= "v" and mode ~= "V" and mode ~= "\22" then
    return nil
  end
  local start_pos = vim.fn.getpos("v")
  local end_pos = vim.fn.getpos(".")
  local srow, scol = start_pos[2], start_pos[3]
  local erow, ecol = end_pos[2], end_pos[3]
  if srow == 0 or erow == 0 then
    return nil
  end
  if srow > erow or (srow == erow and scol > ecol) then
    srow, erow = erow, srow
    scol, ecol = ecol, scol
  end
  local lines = vim.api.nvim_buf_get_lines(0, srow - 1, erow, false)
  if #lines == 0 then
    return nil
  end
  lines[#lines] = string.sub(lines[#lines], 1, ecol)
  lines[1] = string.sub(lines[1], scol)
  return table.concat(lines, "\n")
end

function M.capture(_opts)
  local selection = get_selection()
  return {
    selection = selection,
    filetype = vim.bo.filetype,
    filepath = vim.api.nvim_buf_get_name(0),
  }
end

return M
