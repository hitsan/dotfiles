return {
  {
    "Wansmer/treesj",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    cmd = { "TSJToggle", "TSJSplit", "TSJJoin" },
    keys = {
      { "J", "<cmd>TSJToggle<cr>", desc = "TreeSJ toggle" },
    },
    config = function()
      require("treesj").setup({})
    end,
  },
}
