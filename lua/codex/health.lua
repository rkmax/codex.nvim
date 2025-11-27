local config = require("codex.config")

local health = vim.health or require("vim.health")

local function ok(msg)
  health.report_ok(msg)
end

local function warn(msg)
  health.report_warn(msg)
end

local function error(msg)
  health.report_error(msg)
end

local function has_min_version()
  local v = vim.version()
  if not v then
    return false, "cannot detect Neovim version"
  end
  if v.major > 0 then
    return true
  end
  if v.minor >= 9 then
    return true
  end
  return false, ("Neovim 0.9+ required, found %s.%s.%s"):format(v.major, v.minor, v.patch)
end

local function check_auth(cfg)
  local home = vim.fn.expand("~/.codex/auth.json")
  local has_file = vim.fn.filereadable(home) == 1
  local has_env = (vim.env.OPENAI_API_KEY and vim.env.OPENAI_API_KEY ~= "")
    or (vim.env.CODEX_API_KEY and vim.env.CODEX_API_KEY ~= "")

  if has_file then
    ok("Auth file present at ~/.codex/auth.json")
  elseif has_env then
    warn("Auth file missing; API key present in environment")
  else
    error("No auth found. Login via codex CLI or set OPENAI_API_KEY/CODEX_API_KEY")
  end

  if cfg.profile then
    ok(("Profile configured: %s"):format(cfg.profile))
  end
end

local function check_plenary()
  local ok_req = pcall(require, "plenary.curl")
  if ok_req then
    ok("plenary.curl available")
  else
    warn("plenary.curl not found; HTTP client may be unavailable")
  end
end

local function check_git()
  if vim.fn.executable("git") == 0 then
    warn("git not found in PATH; Codex may require --skip-git-repo-check")
    return
  end
  local root = vim.fn.systemlist("git rev-parse --show-toplevel")
  if vim.v.shell_error ~= 0 or not root[1] or root[1] == "" then
    warn("Not in a git repository; Codex CLI may refuse to run without --skip-git-repo-check")
  else
    ok(("Git root detected: %s"):format(root[1]))
  end
end

local function check_base_url(cfg)
  if cfg.base_url and cfg.base_url ~= "" then
    ok(("Base URL configured: %s"):format(cfg.base_url))
  else
    warn("Base URL not set; using defaults")
  end
end

local function check_cli()
  if vim.fn.executable("codex") == 1 then
    ok("codex CLI available in PATH")
  else
    warn("codex CLI not found; exec integration will be unavailable")
  end
end

local M = {}

function M.check()
  health.report_start("codex")

  local cfg = config.get()

  local version_ok, version_msg = has_min_version()
  if version_ok then
    ok("Neovim version OK")
  else
    error(version_msg or "Neovim version check failed")
  end

  check_plenary()
  check_auth(cfg)
  check_git()
  check_base_url(cfg)
  check_cli()

  health.report_ok("Health checks completed")
end

return M
