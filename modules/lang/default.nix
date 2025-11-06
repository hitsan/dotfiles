{ pkgs, ... }:
{
 home.packages = with pkgs; [
    clang
    nodejs
    uv
  ];
}
