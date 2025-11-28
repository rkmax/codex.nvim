local inspect = require("vim.inspect")

local real_vim = _G.vim
local real_fn = real_vim.fn
local real_env = real_vim.env
local real_v = real_vim.v

local function fake_vim_env(opts)
  local calls = {}
  vim.env = opts.env or {}
  vim.v = { shell_error = opts.shell_error or 0 }
  vim.fn = setmetatable({
    executable = function()
      calls.executable = true
      return opts.git_executable or 1
    end,
    filereadable = function()
      calls.filereadable = true
      return opts.auth_present and 1 or 0
    end,
    expand = function(path)
      return path:gsub("~", "/home/test")
    end,
    systemlist = function()
      calls.systemlist = true
      return { "/home/test/repo" }
    end,
    isdirectory = function()
      return opts.prompt_dir_exists and 1 or 0
    end,
    readfile = function()
      return {}
    end,
    writefile = function() end,
  }, { __index = real_fn })

  return calls, function()
    vim.fn = real_fn
    vim.env = real_env
    vim.v = real_v
  end
end

describe("health checks", function()
  it("uses report_* API when available", function()
    package.loaded["codex.config"] = {
      get = function()
        return {
          prompt_dir = "/tmp/prompts",
          base_url = "http://example.com",
          profile = nil,
        }
      end,
    }

    local _, restore = fake_vim_env({
      auth_present = true,
      git_executable = 1,
      prompt_dir_exists = true,
    })

    local reporter_calls = {}
    local reporter = {
      report_start = function(name)
        reporter_calls.start = name
      end,
      report_ok = function(msg)
        reporter_calls.ok = (reporter_calls.ok or 0) + 1
      end,
      report_warn = function(msg)
        reporter_calls.warn = (reporter_calls.warn or 0) + 1
      end,
      report_error = function(msg)
        reporter_calls.error = (reporter_calls.error or 0) + 1
      end,
    }
    package.loaded["vim.health"] = reporter
    vim.health = reporter

    package.loaded["codex.health"] = nil
    local health = require("codex.health")
    assert.has_no.errors(function()
      health.check()
    end)
    assert.equals("codex", reporter_calls.start)
    assert.truthy(reporter_calls.ok and reporter_calls.ok > 0)
    restore()
  end)

  it("falls back to legacy health API when report_* missing", function()
    pending("Legacy health path not exercised in this environment")
  end)
end)
