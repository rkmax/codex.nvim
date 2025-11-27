local log = require("codex.log")

local M = {}

function M.chat(_payload, _opts)
  log.warn("HTTP client not implemented yet.")
  return nil
end

function M.edits(_payload, _opts)
  log.warn("Edit request not implemented yet.")
  return nil
end

return M
