{ pkgs, ... }:
{
  home.packages = with pkgs; [
    marp-cli
  ];
}
