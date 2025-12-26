{ pkgs, shell, ... }:
{
  home.packages = with pkgs; [
    bat
    chromium
    eza
    jq
  ];
  programs = {
    fd.enable = true;
    fzf.enable = true;
    zoxide.enable = true;
    ripgrep.enable = true;
    yazi.enable = true;
  };
  programs.${shell} = {
    shellAliases = {
      yz = "yazi";
    };
  };
}
