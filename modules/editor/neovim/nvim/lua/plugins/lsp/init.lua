return {
  {
    "neovim/nvim-lspconfig",
    config = function()
      vim.diagnostic.config({
        virtual_text = true,
      })

      local capabilities = require("cmp_nvim_lsp").default_capabilities()
      local on_attach = function(_, bufnr)
        local map = function(mode, lhs, rhs)
          vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, noremap = true, silent = true })
        end
        map("n", "gd", vim.lsp.buf.definition)
        map("n", "K", vim.lsp.buf.hover)
      end

      require("plugins.lsp.servers.rust")(capabilities, on_attach)
      require("plugins.lsp.servers.go")(capabilities, on_attach)
      require("plugins.lsp.servers.verilog")(capabilities, on_attach)
      require("plugins.lsp.servers.web")(capabilities, on_attach)
    end,
  },
}
