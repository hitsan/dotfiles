{ pkgs, ... }:
{
 home.packages = with pkgs; [
    gcc
    nodejs
    python3
    uv
  ];
}
