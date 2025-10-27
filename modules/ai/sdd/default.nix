{ pkgs, ... }:
{
  home.packages = with pkgs; [
    nodePackages."@fission-ai/openspec"
  ];
}
