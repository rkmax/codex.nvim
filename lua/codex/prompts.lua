local config = require("codex.config")
local log = require("codex.log")
local ctx = require("codex.context")
local client = require("codex.client.http")
local chat_ui = require("codex.ui.chat")

local M = {}

local function list_prompts(dir)
  local files = vim.fn.globpath(dir, "*.md", false, true)
  local names = {}
  for _, file in ipairs(files) do
    local name = vim.fn.fnamemodify(file, ":t:r")
    table.insert(names, name)
  end
  return names
end

local function read_prompt_file(dir, name)
  local path = dir .. "/" .. name .. ".md"
  local ok, content = pcall(vim.fn.readfile, path)
  if not ok then
    return nil, ("Failed to read prompt file: %s"):format(path)
  end
  return table.concat(content, "\n"), nil
end

local function expand_placeholders(text, args)
  if not args or args == "" then
    return text
  end
  -- Very naive expansion: replace $ARGUMENTS
  return text:gsub("%$ARGUMENTS", args)
end

function M.list()
  local dir = config.get().prompt_dir
  return list_prompts(dir)
end

function M.run(name, args)
  if not name or name == "" then
    log.warn("Prompt name is required.")
    return
  end
  local dir = config.get().prompt_dir
  local content, err = read_prompt_file(dir, name)
  if err then
    log.error(err)
    return
  end
  local prompt = expand_placeholders(content, args)
  -- Fire through chat UI so we keep consistent UX.
  chat_ui.open({ prompt = prompt, transcript = { { role = "user", content = prompt }, { role = "assistant", content = "(pending)" } } })
end

return M
