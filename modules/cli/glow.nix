{ pkgs, shell, ... }:
{
  home.packages = [ pkgs.glow ];
  programs.${shell}.shellAliases.glow = "glow -p -w $(tput cols)";
}
