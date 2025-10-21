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
    ssh = {
      enable = true;
      addKeysToAgent = "yes";
    };
  };
  
  services.ssh-agent.enable = true;
  imports = [ 
    ./home/packages.nix
    ./home/shell.nix
  ];
}