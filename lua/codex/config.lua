local M = {}

local defaults = {
  model = "gpt-5.1-codex",
  model_provider = "openai",
  profile = nil,
  reasoning_effort = "medium", -- low | medium | high
  sandbox_mode = "read-only",
  approval_policy = "on-request",
  request_timeout_ms = 120000,
  stream_idle_timeout_ms = 300000,
  prompt_dir = vim.fn.expand("~/.codex/prompts"),
  log_level = "info",
  structured_output = false,
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

function M.get()
  return current
end

function M.defaults()
  return defaults
end

return M
