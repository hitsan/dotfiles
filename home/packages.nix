{ pkgs, ... }:
{
  home.packages = with pkgs; [
    bat
    eza
    jq
  ];
  programs = {
    fzf.enable = true;
    zoxide.enable = true;
    ripgrep.enable = true;
  };
}
