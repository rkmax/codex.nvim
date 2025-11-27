local log = require("codex.log")

local M = {}

function M.run(name, args)
  if not name or name == "" then
    log.warn("Prompt name is required.")
    return
  end
  log.warn(("Prompt %s not implemented yet. Args: %s"):format(name, args or ""))
end

return M
