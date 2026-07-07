return function(capabilities, on_attach)
  vim.lsp.config("gopls", {
    on_attach = on_attach,
    filetypes = { "go", "gomod", "gowork", "gotmpl" },
    capabilities = capabilities,
    root_dir = function(bufnr, on_dir)
      on_dir(vim.fs.root(bufnr, { "go.work", "go.mod", ".git" }))
    end,
    settings = {
      gopls = {
        analyses = {
          unusedparams = true,
        },
        staticcheck = true,
      },
    },
  })

  vim.lsp.enable("gopls")
end
