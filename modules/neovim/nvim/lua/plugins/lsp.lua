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

      -- SystemVerilog LSP: verible-verilog-ls
      local verible_filetypes = { "systemverilog", "verilog" }
      vim.lsp.config("verible", {
        cmd = { "verible-verilog-ls", "--rules_config_search" },
        on_attach = on_attach,
        filetypes = verible_filetypes,
        capabilities = capabilities,
        root_dir = vim.fs.root(0, { ".git", "verible.filelist" }),
      })

      -- SystemVerilog LSP: svlangserver
      vim.lsp.config("svls", {
        cmd = { "svls" },
        on_attach = on_attach,
        filetypes = verible_filetypes,
        capabilities = capabilities,
        root_dir = vim.fs.root(0, { ".git" }),
        settings = {
          systemverilog = {
            includeIndexing = { "**/*.{sv,svh,v,vh}" },
          },
        },
      })

      vim.api.nvim_create_autocmd("FileType", {
        pattern = verible_filetypes,
        callback = function(event)
          local verible_config = vim.lsp.config["verible"]
          local svls_config = vim.lsp.config["svls"]
          if verible_config then
            vim.lsp.start(verible_config, { bufnr = event.buf })
          end
          if svls_config then
            vim.lsp.start(svls_config, { bufnr = event.buf })
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
