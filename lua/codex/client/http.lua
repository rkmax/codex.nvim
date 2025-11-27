local curl_ok, curl = pcall(require, "plenary.curl")
local log = require("codex.log")
local config = require("codex.config")

local M = {}

local function auth_header()
  local key = vim.env.OPENAI_API_KEY or vim.env.CODEX_API_KEY
  if not key or key == "" then
    return nil
  end
  return "Bearer " .. key
end

local function decode(body)
  local ok, parsed = pcall(vim.json.decode, body or "")
  if not ok then
    return nil, "Failed to decode response JSON"
  end
  return parsed, nil
end

local function post_json(path, payload)
  if not curl_ok then
    return nil, "plenary.curl not available"
  end
  local cfg = config.get()
  local headers = {
    ["Content-Type"] = "application/json",
  }
  local auth = auth_header()
  if auth then
    headers["Authorization"] = auth
  end

  local res = curl.post({
    url = cfg.base_url .. path,
    headers = headers,
    timeout = cfg.request_timeout_ms / 1000,
    body = vim.json.encode(payload),
  })

  if not res then
    return nil, "No response from server"
  end

  if res.status ~= 200 then
    local parsed_err, _ = decode(res.body)
    local detail = parsed_err and (parsed_err.detail or parsed_err.error and parsed_err.error.message)
    local status = res.status or "unknown"
    return nil, ("HTTP error %s: %s"):format(status, detail or "unknown error")
  end

  return decode(res.body)
end

local function normalize_output(parsed)
  if not parsed then
    return nil
  end

  if parsed.output and type(parsed.output) == "string" then
    return parsed.output
  end

  if parsed.output and type(parsed.output) == "table" and parsed.output[1] then
    if type(parsed.output[1]) == "string" then
      return parsed.output[1]
    end
    if parsed.output[1].content then
      return parsed.output[1].content
    end
  end

  if parsed.message and parsed.message.content then
    return parsed.message.content
  end

  return vim.inspect(parsed)
end

function M.chat(prompt, ctx)
  local cfg = config.get()
  local payload = {
    model = cfg.model,
    input = prompt,
    reasoning = { effort = cfg.reasoning_effort },
    stream = false,
    metadata = {
      filetype = ctx and ctx.filetype or nil,
      filepath = ctx and ctx.filepath or nil,
    },
  }

  local parsed, err = post_json("/responses", payload)
  if err then
    return nil, err
  end

  return normalize_output(parsed), nil
end

function M.edits(prompt, ctx)
  -- Placeholder for edits endpoint.
  local response, err = M.chat(prompt, ctx)
  if err then
    return nil, err
  end
  return response, nil
end

return M
