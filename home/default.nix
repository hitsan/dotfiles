{ pkgs, user, home, shell, ... }:
{
  home.username = user;
  home.homeDirectory = home;
  home.stateVersion = "25.05";

  home.file = { };

  home.sessionVariables = {
    EDITOR = "nvim";
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
  programs = {
    ssh = {
      enable = true;
      matchBlocks = {
        "*" = {
          addKeysToAgent = "yes";
        };
      };
    };
  };
  
  services.ssh-agent.enable = true;
  imports = [
    ./packages.nix
    ./shell.nix
  ];
}
