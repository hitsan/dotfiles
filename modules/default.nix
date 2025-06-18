{ pkgs, ... }:
{
  imports = [
    ./shell
    ./zellij
    ./editor
    ./git
    ./dev
    ./docker
    ./xremap
  ];
}
