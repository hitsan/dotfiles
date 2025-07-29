return {
  "akinsho/toggleterm.nvim",
  version = "*",
  config = function()
    require("toggleterm").setup({
      direction = "float",
      close_on_exit = true,
      start_in_insert = true,
      shell = vim.o.shell,
    })

    vim.keymap.set("n", "<leader>\\", "<cmd>ToggleTerm<CR>", { desc = "ToggleTerm", noremap = true, silent = true })
  end,
}


