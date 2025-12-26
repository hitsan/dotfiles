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

      -- Verilog LSP: verible-verilog-ls (for .v, .vh files)
      vim.lsp.config("verible", {
        cmd = { "verible-verilog-ls", "--rules_config_search" },
        on_attach = on_attach,
        filetypes = { "verilog" },
        capabilities = capabilities,
        root_dir = vim.fs.root(0, { ".git", "verible.filelist" }),
      })

      vim.api.nvim_create_autocmd("FileType", {
        pattern = { "verilog" },
        callback = function(event)
          local verible_config = vim.lsp.config["verible"]
          if verible_config then
            vim.lsp.start(verible_config, { bufnr = event.buf })
          end
        end,
      })

      -- SystemVerilog LSP: svlangserver (for .sv, .svh files)
      vim.lsp.config("svls", {
        cmd = { "svls" },
        on_attach = on_attach,
        filetypes = { "systemverilog" },
        capabilities = capabilities,
        root_dir = vim.fs.root(0, { ".git" }),
        settings = {
          systemverilog = {
            includeIndexing = { "**/*.{sv,svh}" },
          },
        },
      })

      vim.api.nvim_create_autocmd("FileType", {
        pattern = { "systemverilog" },
        callback = function(event)
          local svls_config = vim.lsp.config["svls"]
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
