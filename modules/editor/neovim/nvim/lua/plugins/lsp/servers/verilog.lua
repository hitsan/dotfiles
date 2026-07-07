return function(capabilities, on_attach)
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
end
