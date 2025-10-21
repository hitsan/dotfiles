{ pkgs, user, home, shell, ... }:
{
  home.username = user;
  home.homeDirectory = home;
  home.stateVersion = "24.05";

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
  imports = [ 
    ./packages.nix
    ./shell.nix
  ];
}
