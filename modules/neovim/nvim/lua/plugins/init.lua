local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  {
    "rebelot/kanagawa.nvim",
    priority = 1000,
    config = function()
      require("kanagawa").setup({
        transparent = true,
      })
      vim.cmd.colorscheme "kanagawa"
    end,
  },
  { import = "plugins.gitsigns" },
  { import = "plugins.lsp" },
  { import = "plugins.cmp" },
  { import = "plugins.treesitter" },
  { import = "plugins.treesj" },
  { import = "plugins.formatter" },
  { import = "plugins.neotree" },
  { import = "plugins.devicons" },
  { import = "plugins.toggleterm" },
  { import = "plugins.which-key" },
})
