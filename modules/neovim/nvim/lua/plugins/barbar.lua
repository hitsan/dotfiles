return {
  {
    "romgrk/barbar.nvim",
    event = "BufAdd",
    init = function()
      vim.g.barbar_auto_setup = false
    end,
    dependencies = {
      "lewis6991/gitsigns.nvim",
      "nvim-tree/nvim-web-devicons",
    },
    opts = {
      animation = true,
      focus_on_close = "left",
      highlight_visible = true,
      sidebar_filetypes = {
        ["neo-tree"] = { event = "BufWipeout" },
      },
    },
    keys = {
      { "<leader>bn", "<cmd>BufferNext<cr>", desc = "Next buffer" },
      { "<leader>bp", "<cmd>BufferPrevious<cr>", desc = "Previous buffer" },
      { "<leader>bc", "<cmd>BufferClose<cr>", desc = "Close buffer" },
      { "<leader>bl", "<cmd>BufferLast<cr>", desc = "Last buffer" },
      { "<leader>bf", "<cmd>BufferFirst<cr>", desc = "First buffer" },
    },
  },
}
