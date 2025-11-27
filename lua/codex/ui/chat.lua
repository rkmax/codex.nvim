local log = require("codex.log")

local M = {}

function M.open(opts)
  opts = opts or {}
  log.warn("Chat UI not implemented yet. Prompt: " .. (opts.prompt or ""))
end

function M.ask(kind, opts)
  opts = opts or {}
  log.warn(("Command %s not implemented yet."):format(kind))
end

return M
