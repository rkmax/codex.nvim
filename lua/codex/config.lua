local M = {}

local defaults = {
  model = "gpt-5.1-codex",
  model_provider = "openai",
  base_url = "https://api.openai.com/v1",
  profile = nil,
  reasoning_effort = "medium", -- low | medium | high
  sandbox_mode = "read-only",
  approval_policy = "on-request",
  request_timeout_ms = 120000,
  stream_idle_timeout_ms = 300000,
  prompt_dir = vim.fn.expand("~/.codex/prompts"),
  log_level = "info",
  structured_output = false,
  available_models = { "gpt-5.1-codex", "gpt-4.1", "gpt-4o-mini" },
  available_sandbox_modes = { "read-only", "workspace-write", "danger-full-access" },
  cli = {
    enabled = false,
    command = "codex",
    args = { "--json" },
    mux = nil, -- "tmux" | "zellij"
  },
  ui = {
    chat = {
      border = "single",
      width = 0.6,
      height = 0.6,
    },
    diff = {
      border = "single",
    },
    log = {
      border = "single",
      show_commands = false,
      show_file_changes = false,
      show_web = false,
    },
  },
}

local current = vim.deepcopy(defaults)

function M.set(user)
  if type(user) ~= "table" then
    return
  end
  current = vim.tbl_deep_extend("force", vim.deepcopy(defaults), user)
end

function M.update(partial)
  if type(partial) ~= "table" then
    return
  end
  current = vim.tbl_deep_extend("force", current, partial)
end

function M.get()
  return current
end

function M.defaults()
  return defaults
end

return M
