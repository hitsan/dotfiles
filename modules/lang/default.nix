{ pkgs, ... }:
{
 home.packages = with pkgs; [
    clang
    uv
  ];
}
