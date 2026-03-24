-- Minimal init for running tests
-- Adds the plugin to the runtime path
vim.opt.rtp:prepend(".")
vim.cmd("runtime plugin/plenary.vim")
