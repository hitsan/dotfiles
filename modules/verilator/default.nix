{ pkgs, ... }:
{
  home.packages = with pkgs; [
    verible
  ];
}
