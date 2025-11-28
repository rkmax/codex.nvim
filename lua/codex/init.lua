local config = require("codex.config")
local commands = require("codex.commands")
local state = require("codex.state")

local M = {}

function M.setup(user_config)
  config.set(user_config or {})
  state.load()
  commands.register()
end

return M
