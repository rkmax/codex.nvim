local chat = require("codex.ui.chat")
local prompts = require("codex.prompts")
local status = require("codex.ui.status")
local exec = require("codex.client.exec")
local health = require("codex.health")
local log = require("codex.log")

local M = {}

local function create(name, opts, fn)
  vim.api.nvim_create_user_command(name, function(command_opts)
    fn(command_opts)
  end, opts)
end

function M.register()
  create("CodexChat", { nargs = "?", desc = "Open Codex chat" }, function(opts)
    chat.open({ prompt = opts.args })
  end)

  create("CodexAsk", { nargs = "*", desc = "Ask Codex about selection/file" }, function(opts)
    chat.ask("ask", { prompt = opts.args })
  end)

  create("CodexExplain", { nargs = "*", desc = "Explain selection/file" }, function(opts)
    chat.ask("explain", { prompt = opts.args })
  end)

  create("CodexFix", { nargs = "*", desc = "Request a fix for selection/file" }, function(opts)
    chat.ask("fix", { prompt = opts.args })
  end)

  create("CodexApply", { nargs = "*", desc = "Apply edits to buffer" }, function(opts)
    chat.apply({ prompt = opts.args })
  end)

  create("CodexPrompt", { nargs = "+", desc = "Run a prompt by name" }, function(opts)
    local args = vim.split(opts.args, " ", { trimempty = true })
    local name = table.remove(args, 1)
    prompts.run(name, table.concat(args, " "))
  end)

  create("CodexLog", { nargs = 0, desc = "Show Codex event log" }, function()
    status.open()
  end)

  create("CodexExec", { nargs = "+", desc = "Run codex exec --json" }, function(opts)
    exec.run(opts.args, {})
  end)

  create("CodexExecResume", { nargs = 0, desc = "Resume last codex exec session" }, function()
    exec.resume({})
  end)

  create("CodexHealth", { nargs = 0, desc = "Run Codex health checks" }, function()
    health.check()
  end)

  log.info("Codex commands registered.")
end

return M
