local log = require("codex.log")

local M = {
  transcript = {},
}

local function storage_path()
  local base = vim.fn.stdpath("cache")
  return base .. "/codex_transcript.json"
end

function M.save()
  local ok, data = pcall(vim.json.encode, M.transcript)
  if not ok then
    log.warn("Failed to encode transcript")
    return
  end
  local ok_write = pcall(vim.fn.writefile, { data }, storage_path())
  if not ok_write then
    log.warn("Failed to save transcript")
  end
end

function M.load()
  local path = storage_path()
  if vim.fn.filereadable(path) == 0 then
    return
  end
  local ok, content = pcall(vim.fn.readfile, path)
  if not ok or not content[1] then
    return
  end
  local ok_decode, decoded = pcall(vim.json.decode, content[1])
  if ok_decode and type(decoded) == "table" then
    M.transcript = decoded
  end
end

function M.add_message(role, content)
  table.insert(M.transcript, { role = role, content = content })
  M.save()
end

function M.get_transcript()
  return M.transcript
end

function M.reset()
  M.transcript = {}
  local path = storage_path()
  pcall(vim.fn.delete, path)
end

return M
