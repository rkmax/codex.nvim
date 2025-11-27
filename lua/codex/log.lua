local M = {}

local levels = { debug = 1, info = 2, warn = 3, error = 4 }

local function notify(msg, level)
  local cfg = require("codex.config").get()
  local threshold = levels[cfg.log_level] or levels.info
  local numeric = levels[level] or levels.info
  if numeric < threshold then
    return
  end
  vim.notify(("Codex: %s"):format(msg), vim.log.levels[string.upper(level)] or vim.log.levels.INFO)
end

function M.debug(msg)
  notify(msg, "debug")
end

function M.info(msg)
  notify(msg, "info")
end

function M.warn(msg)
  notify(msg, "warn")
end

function M.error(msg)
  notify(msg, "error")
end

return M
