{ config, pkgs, lib, user, home, shell, modules, xremap, ... }:
{
  home.username = user;
  home.homeDirectory = home;
  home.stateVersion = "24.05";

  home.packages = with pkgs; [
    bat
    eza
    jq
  ];
  home.file = { };

  home.sessionVariables = {
    EDITOR = "nvim";
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
  programs = {
    fzf.enable = true;
    zoxide.enable = true;
  };
  programs.${shell}.shellAliases = {
    l = "eza";
    ll = "eza -l";
    lt = "eza -T";
    home = "home-manager switch --flake ~/dotfiles#hitsan";
    hflake = "home-manager switch --flake ~/dotfiles#hitsan";
  };
  imports = [ modules ];
}
