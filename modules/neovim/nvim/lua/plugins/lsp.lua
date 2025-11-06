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
        capabilities = capabilities,
      })

      local gopls_filetypes = { "go", "gomod", "gowork", "gotmpl" }
      vim.lsp.config("gopls", {
        on_attach = on_attach,
        filetypes = gopls_filetypes,
        capabilities = capabilities,
        settings = {
          gopls = {
            analyses = {
              unusedparams = true,
            },
            staticcheck = true,
          },
        },
      })

      vim.api.nvim_create_autocmd("FileType", {
        pattern = gopls_filetypes,
        callback = function(event)
          local config = vim.lsp.config["gopls"]
          if config then
            vim.lsp.start(config, { bufnr = event.buf })
          end
        end,
      })

      vim.lsp.enable({
        "rust_analyzer",
        "nixd",
      })
    end,
  },
}
