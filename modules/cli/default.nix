{ pkgs, ... }:
{
  home.packages = with pkgs; [
    bat
    eza
    jq
  ];
  programs = {
    fd.enable = true;
    fzf.enable = true;
    zoxide.enable = true;
    ripgrep.enable = true;
  };
}
