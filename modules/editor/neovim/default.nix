{ pkgs, shell, ... }:
{
  programs.neovim = {
    enable = true;
  };
  programs.${shell}.shellAliases = {
    v = "nvim";
  };
  home.file.".config/nvim" = {
    source = ./nvim;
    recursive = true;
  };
  home.packages = with pkgs; [
    rust-analyzer
    gopls
    tree-sitter
  ];
}
