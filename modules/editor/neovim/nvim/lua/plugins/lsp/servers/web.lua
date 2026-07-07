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
    callback = function(args)
      local clients = vim.lsp.get_clients({ bufnr = args.buf, name = "eslint" })
      if #clients == 0 then
        return
      end
      local client = clients[1]

      -- code_action() is async, so a fire-and-forget call here can leave the
      -- fix unapplied by the time BufWritePre returns and the write happens.
      -- Block synchronously so the fix lands before the file is saved.
      local params = vim.lsp.util.make_range_params(0, client.offset_encoding)
      params.context = { only = { "source.fixAll.eslint" }, diagnostics = {} }
      local result = client:request_sync("textDocument/codeAction", params, 1000, args.buf)
      if not result or not result.result then
        return
      end

      for _, action in ipairs(result.result) do
        if action.edit then
          vim.lsp.util.apply_workspace_edit(action.edit, client.offset_encoding)
        elseif action.command then
          client:exec_cmd(action.command, { bufnr = args.buf })
        end
      end
    end,
  })
end
