local log = require("codex.log")
local status = require("codex.ui.status")
local config = require("codex.config")

local M = {}

local function handle_line(line)
  local ok, obj = pcall(vim.json.decode, line)
  if not ok then
    return
  end
  if obj.type == "item.completed" or obj.type == "item.started" then
    status.append_event(obj.item)
  elseif obj.type == "item.updated" then
    status.append_event(obj.item)
  elseif obj.type == "item.completed" then
    status.append_event(obj.item)
  elseif obj.type == "item.completed" then
    status.append_event(obj.item)
  elseif obj.type == "item.completed" then
    status.append_event(obj.item)
  elseif obj.type == "error" then
    status.append_event({ type = "agent_message", text = obj.message })
  end
end

local function spawn_cmd(prompt, opts)
  opts = opts or {}
  local cfg = config.get()
  local cmd = { cfg.cli.command or "codex", "--json" }
  if opts.resume then
    table.insert(cmd, "resume")
    table.insert(cmd, "--last")
  else
    table.insert(cmd, prompt)
  end

  status.open()

  local handle
  handle = vim.fn.jobstart(cmd, {
    stdout_buffered = false,
    on_stdout = function(_, data, _)
      for _, line in ipairs(data) do
        if line and line ~= "" then
          handle_line(line)
        end
      end
    end,
    on_stderr = function(_, data, _)
      for _, line in ipairs(data) do
        if line and line ~= "" then
          log.warn(line)
        end
      end
    end,
    on_exit = function(_, code, _)
      if code ~= 0 then
        log.error(("codex exec exited with code %s"):format(code))
      end
    end,
  })

  if handle <= 0 then
    log.error("Failed to start codex exec job.")
  end
end

function M.run(prompt, opts)
  spawn_cmd(prompt, opts)
end

function M.resume(opts)
  spawn_cmd(nil, vim.tbl_extend("keep", opts or {}, { resume = true }))
end

return M
