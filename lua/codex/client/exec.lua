local log = require("codex.log")
local status = require("codex.ui.status")
local config = require("codex.config")

local M = {}

local function normalize_item(obj)
  if not obj or not obj.item then
    return nil
  end
  local item = obj.item
  local kind = item.type or "unknown"

  if kind == "command_execution" then
    return {
      kind = kind,
      command = item.command,
      text = item.aggregated_output,
      status = item.status,
      exit_code = item.exit_code,
    }
  elseif kind == "agent_message" or kind == "reasoning" or kind == "web_search" or kind == "todo_list" then
    return {
      kind = kind,
      text = item.text,
    }
  elseif kind == "file_change" then
    return {
      kind = kind,
      text = item.path or item.summary or "file change",
    }
  else
    return {
      kind = kind,
      text = item.text or item.summary,
    }
  end
end

local function handle_line(line)
  local ok, obj = pcall(vim.json.decode, line)
  if not ok then
    return
  end
  if obj.type == "item.completed" or obj.type == "item.updated" or obj.type == "item.started" then
    local norm = normalize_item(obj)
    if norm then
      status.append_event(norm)
    end
  elseif obj.type == "error" then
    status.append_event({ kind = "agent_message", text = obj.message })
  end
end

local function spawn_cmd(prompt, opts)
  opts = opts or {}
  local cfg = config.get()
  local cmd = { cfg.cli.command or "codex", "--json" }
  if opts.resume then
    table.insert(cmd, "resume")
    table.insert(cmd, "--last")
  elseif prompt and prompt ~= "" then
    table.insert(cmd, prompt)
  else
    log.warn("No prompt provided for Codex exec.")
    return
  end

  status.open()

  local handle = vim.fn.jobstart(cmd, {
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
