return function(capabilities, on_attach)
  local filetypes = { "go", "gomod", "gowork", "gotmpl" }

  vim.lsp.config("gopls", {
    on_attach = on_attach,
    filetypes = filetypes,
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
    pattern = filetypes,
    callback = function(event)
      local config = vim.lsp.config["gopls"]
      if config then
        vim.lsp.start(config, { bufnr = event.buf })
      end
    end,
  })
end
