{ pkgs, ... }:
{
  home.packages = with pkgs; [
    bat
    eza
    jq
    fzf
    zoxide
  ];
}