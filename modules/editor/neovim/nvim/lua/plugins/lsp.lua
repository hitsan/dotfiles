return {
  {
    "neovim/nvim-lspconfig",
    config = function()
      local on_attach = function(_, bufnr)
        local map = function(mode, lhs, rhs)
          vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, noremap = true, silent = true })
        end
        map("n", "gd", vim.lsp.buf.definition)
        map("n", "K", vim.lsp.buf.hover)
      end

      require("lspconfig").rust_analyzer.setup({
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

      require("lspconfig").gopls.setup({
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
    end,
  },
}

