{ pkgs, ... }:
{
  home.packages = with pkgs; [
    verilator
    verible
  ];
}
