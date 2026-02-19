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
        cmd = { vim.fn.exepath("rust-analyzer") },
        handlers = {
          ["textDocument/signatureHelp"] = function() end,
        },
        settings = {
          ["rust-analyzer"] = {
            cargo = {
              allFeatures = false,
            },
            checkOnSave = false,
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

      -- Ensure .sv and .svh files are recognized as SystemVerilog
      vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
        pattern = { "*.sv", "*.svh" },
        callback = function()
          vim.bo.filetype = "systemverilog"
        end,
      })

      -- SystemVerilog LSP: svls (supports both Verilog and SystemVerilog)
      -- SystemVerilog is a superset of Verilog, so svls handles both
      vim.lsp.config("svls", {
        cmd = { "svls" },
        on_attach = on_attach,
        filetypes = { "verilog", "systemverilog" },
        capabilities = capabilities,
        root_dir = vim.fs.root(0, { ".git" }),
        settings = {
          systemverilog = {
            -- Enable SystemVerilog syntax (always_comb, etc.)
            includeIndexing = { "**/*.{sv,svh,v,vh}" },
            -- Disable Verilog-only linting rules
            disableCompletionProvider = false,
            disableHoverProvider = false,
            disableSignatureHelpProvider = false,
          },
        },
      })

      vim.api.nvim_create_autocmd("FileType", {
        pattern = { "verilog", "systemverilog" },
        callback = function(event)
          local svls_config = vim.lsp.config["svls"]
          if svls_config then
            vim.lsp.start(svls_config, { bufnr = event.buf })
          end
        end,
      })

      local servers_to_enable = { "nixd" }
      if vim.fn.executable("cargo") == 1 then
        table.insert(servers_to_enable, "rust_analyzer")
      end
      vim.lsp.enable(servers_to_enable)
    end,
  },
}
