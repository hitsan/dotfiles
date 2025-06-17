{ pkgs, shell, ... }:
{
  home.packages = with pkgs; [
    typst
  ];
}
