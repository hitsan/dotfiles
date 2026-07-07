return {
  "akinsho/toggleterm.nvim",
  version = "*",
  keys = {
    { "<C-\\>", "<cmd>ToggleTerm<CR>", desc = "ToggleTerm" },
  },
  config = function()
    require("toggleterm").setup({
      direction = "float",
      close_on_exit = true,
      start_in_insert = true,
      shell = vim.o.shell,
    })
  end,
}

