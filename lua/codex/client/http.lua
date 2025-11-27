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

function M.chat_stream(prompt, ctx, handlers)
  handlers = handlers or {}
  if not curl_ok then
    if handlers.on_error then
      handlers.on_error("plenary.curl not available")
    end
    return
  end

  local cfg = config.get()
  local headers = {
    ["Content-Type"] = "application/json",
    ["Accept"] = "text/event-stream",
  }
  local auth = auth_header()
  if auth then
    headers["Authorization"] = auth
  end

  local payload = {
    model = cfg.model,
    input = prompt,
    reasoning = { effort = cfg.reasoning_effort },
    stream = true,
    metadata = {
      filetype = ctx and ctx.filetype or nil,
      filepath = ctx and ctx.filepath or nil,
    },
  }

  local buffer = ""
  local done = false
  local aggregated = {}

  local function emit_text(text)
    if handlers.on_message then
      handlers.on_message(text)
    end
    table.insert(aggregated, text)
  end

  local function handle_data(raw)
    if raw == "[DONE]" then
      done = true
      return
    end
    local ok, obj = pcall(vim.json.decode, raw)
    if not ok or type(obj) ~= "table" then
      emit_text(raw)
      return
    end
    if obj.type == "response.output_text.delta" and obj.delta then
      emit_text(obj.delta)
    elseif obj.type == "response.output_text" and obj.output_text then
      emit_text(obj.output_text)
    elseif obj.type == "error" and handlers.on_error then
      handlers.on_error(obj.error or obj.message or "Unknown error")
    end
  end

  local function flush_lines()
    local lines = vim.split(buffer, "\n", { plain = true })
    -- keep last as potential partial
    buffer = table.remove(lines)
    for _, line in ipairs(lines) do
      if line ~= "" then
        local data = line
        local prefix = "data:"
        if vim.startswith(line, prefix) then
          data = vim.trim(string.sub(line, #prefix + 1))
        end
        handle_data(data)
      end
    end
  end

  curl.post({
    url = cfg.base_url .. "/responses",
    headers = headers,
    body = vim.json.encode(payload),
    stream = true,
    timeout = cfg.request_timeout_ms / 1000,
    on_chunk = function(chunk, _)
      if chunk and chunk ~= "" then
        buffer = buffer .. chunk
        flush_lines()
      end
    end,
    callback = function(res)
      if res and res.status and res.status ~= 200 and handlers.on_error then
        handlers.on_error(("HTTP error %s"):format(res.status))
      end
      if not done and handlers.on_complete then
        handlers.on_complete(table.concat(aggregated))
      elseif handlers.on_complete then
        handlers.on_complete(table.concat(aggregated))
      end
    end,
  })
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
