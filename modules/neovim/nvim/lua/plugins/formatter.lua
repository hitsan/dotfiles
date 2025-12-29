return {
  {
    "stevearc/conform.nvim",
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      local conform = require("conform")
      
      conform.setup({
        formatters_by_ft = {
          lua = { "stylua" },
          nix = { "nixpkgs-fmt" },
          rust = { "rustfmt" },
          go = { "gofmt" },
          javascript = { "prettier" },
          typescript = { "prettier" },
          json = { "prettier" },
          yaml = { "prettier" },
          markdown = { "prettier" },
          systemverilog = { "verible_verilog_format" },
          verilog = { "verible_verilog_format" },
        },
        formatters = {
          verible_verilog_format = {
            command = "verible-verilog-format",
            args = { "-" },
            stdin = true,
          },
        },
        format_on_save = {
          timeout_ms = 1000,
          lsp_fallback = true,
        },
      })
      
      vim.keymap.set({ "n", "v" }, "<leader>f", function()
        conform.format({
          lsp_fallback = true,
          async = false,
          timeout_ms = 1000,
        })
      end, { desc = "Format file or range (in visual mode)" })
    end,
  },
}