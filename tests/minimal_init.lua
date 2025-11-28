vim.cmd([[
set rtp+=.
set rtp+=./tests/fixtures
set rtp+=~/.local/share/nvim/site/pack/packer/start/plenary.nvim
]])

pcall(require, "plenary.busted")
pcall(function()
  vim.inspect = vim.inspect or require("vim.inspect")
end)
