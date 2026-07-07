{ pkgs, shell, ... }:
{
  home.packages = [ pkgs.eza ];
  programs.${shell}.shellAliases = {
    l = "eza";
    ll = "eza -l";
    lt = "eza -T";
  };
}
