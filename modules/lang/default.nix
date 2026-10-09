{ pkgs, ... }:
{
 programs.uv.enable = true;
 home.packages = with pkgs; [
    gcc
    nodejs
    python3
  ];
}
