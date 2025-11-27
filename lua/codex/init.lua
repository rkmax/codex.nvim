local config = require("codex.config")
local commands = require("codex.commands")

local M = {}

function M.setup(user_config)
  config.set(user_config or {})
  commands.register()
end

return M
