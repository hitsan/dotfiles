return function(capabilities, on_attach)
  local servers_to_enable = { "nixd", "ts_ls", "eslint" }
  for _, server in ipairs(servers_to_enable) do
    vim.lsp.config(server, {
      on_attach = on_attach,
      capabilities = capabilities,
    })
  end
  vim.lsp.enable(servers_to_enable)

  vim.api.nvim_create_autocmd("BufWritePre", {
    pattern = { "*.ts", "*.tsx", "*.js", "*.jsx" },
    callback = function()
      vim.lsp.buf.code_action({
        context = { only = { "source.fixAll.eslint" } },
        apply = true,
      })
    end,
  })
end
