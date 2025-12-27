{ pkgs, ... }:
{
 home.packages = with pkgs; [
    gcc
    nodejs
    uv
  ];
}
