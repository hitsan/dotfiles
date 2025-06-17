{ pkgs, shell, ... }:
{
  imports = [
    ./neovim
    ./typst.nix
  ];
}
