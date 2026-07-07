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
    root_dir = function(bufnr, on_dir)
      on_dir(vim.fs.root(bufnr, { ".git" }))
    end,
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

  vim.lsp.enable("svls")
end
