return function(capabilities, on_attach)
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

  if vim.fn.executable("cargo") == 1 then
    vim.lsp.enable("rust_analyzer")
  end
end
