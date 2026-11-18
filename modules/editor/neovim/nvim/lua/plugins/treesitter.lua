return {
  "nvim-treesitter/nvim-treesitter",
  -- master は Neovim 0.12 の treesitter API と非互換でハイライト時にエラーになる
  branch = "main",
  lazy = false,
  build = ":TSUpdate",
  config = function()
    require("nvim-treesitter").install({ "lua", "vim", "vimdoc", "rust", "go", "bash", "nix", "typescript" })
    vim.api.nvim_create_autocmd("FileType", {
      callback = function()
        if pcall(vim.treesitter.start) then
          vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        end
      end,
    })
  end,
}
