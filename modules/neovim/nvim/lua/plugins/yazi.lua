return {
  "mikavilpas/yazi.nvim",
  version = "*", -- Use latest stable version
  event = "VeryLazy",
  dependencies = {
    { "nvim-lua/plenary.nvim", lazy = true },
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
  opts = {
    -- Enable mouse support
    enable_mouse_support = true,

    -- Open yazi instead of netrw
    open_for_directories = false,

    -- Keymaps to be used inside yazi
    keymaps = {
      show_help = '<f1>',
      open_file_in_vertical_split = "<c-x>",
      open_file_in_horizontal_split = "<c-h>",
      open_file_in_tab = "<c-t>",
      grep_in_directory = "<c-s>",
      copy_relative_path_to_selected_files = "<c-y>",
    },

    -- Floating window settings
    floating_window_scaling_factor = 0.9,
    yazi_floating_window_winblend = 0,
    yazi_floating_window_border = "rounded",
  },
}
