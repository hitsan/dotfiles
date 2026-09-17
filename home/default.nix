{ user, home, ... }:
{
  home.username = user;
  home.homeDirectory = home;
  home.stateVersion = "26.05";

  home.sessionVariables = {
    EDITOR = "nvim";
  };

  programs.home-manager.enable = true;
  programs = {
    ssh = {
      enable = true;
      enableDefaultConfig = false;
      settings."*" = {
        AddKeysToAgent = "yes";
      };
    };
  };

  services.ssh-agent.enable = true;
}
