vim.opt.number = true
vim.opt.cursorline = true
vim.opt.virtualedit = "onemore"
vim.opt.expandtab = true
vim.opt.tabstop = 2
vim.opt.showmatch = true
vim.opt.shiftwidth = 2
vim.opt.clipboard = "unnamedplus"
vim.g.mapleader = " "

local ime_off
if vim.fn.has("wsl") == 1 then
  ime_off = { "/mnt/c/tools/zenhan.exe", "0" }
else
  ime_off = { "fcitx5-remote", "-c" }
end
if vim.fn.executable(ime_off[1]) == 1 then
  vim.api.nvim_create_autocmd("InsertLeave", {
    desc = "IME off",
    callback = function() vim.fn.jobstart(ime_off) end,
  })
end
