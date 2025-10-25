return {
  {
    "neovim/nvim-lspconfig",
    config = function()
      vim.diagnostic.config({
        virtual_text = true,
      })

      local on_attach = function(_, bufnr)
        local map = function(mode, lhs, rhs)
          vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, noremap = true, silent = true })
        end
        map("n", "gd", vim.lsp.buf.definition)
        map("n", "K", vim.lsp.buf.hover)
      end

      vim.lsp.config("rust_analyzer", {
        handlers = {
          ["textDocument/signatureHelp"] = function() end,
        },
        settings = {
          ["rust-analyzer"] = {
            cargo = {
              allFeatures = false,
            },
            checkOnSave = {
              command = "clippy",
            },
            procMacro = {
              enable = false,
            },
          },
        },
        on_attach = on_attach,
      })

      vim.lsp.config("gopls", {
        on_attach = on_attach,
        settings = {
          gopls = {
            analyses = {
              unusedparams = true,
            },
            staticcheck = true,
          },
        },
      })

      vim.lsp.enable({
        "rust_analyzer",
        "gopls",
        "nixd",
      })
    end,
  },
}
