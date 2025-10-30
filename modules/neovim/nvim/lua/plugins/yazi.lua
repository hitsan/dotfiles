return {
  "mikavilpas/yazi.nvim",
  event = "VeryLazy",
  dependencies = {
    "nvim-lua/plenary.nvim",
  },
  keys = {
    {
      "<leader>y",
      "<cmd>Yazi<cr>",
      desc = "Open yazi file manager",
    },
    {
      "<leader>yw",
      "<cmd>Yazi cwd<cr>",
      desc = "Open yazi in current working directory",
    },
  },
  config = function()
    require("yazi").setup({
      -- Enable mouse support
      enable_mouse_support = true,

      -- Open yazi instead of netrw
      open_for_directories = false,

      -- Keymaps to be used inside yazi (optional)
      keymaps = {
        show_help = '<f1>',
      },

      -- Floating window settings
      floating_window_scaling_factor = 0.9,

      -- Yazi specific options
      yazi_floating_window_winblend = 0,
      yazi_floating_window_border = "rounded",
    })
  end,
}
