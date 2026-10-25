{ user, home, ... }:
{
  home.username = user;
  home.homeDirectory = home;
  home.stateVersion = "26.05";

  home.sessionVariables = {
    EDITOR = "nvim";
  };
  home.sessionVariablesExtra = ''
    if [ -n "$WSL_DISTRO_NAME" ]; then
      export WINHOME="$(wslpath "$(/mnt/c/Windows/System32/cmd.exe /c 'echo %USERPROFILE%' 2>/dev/null | tr -d '\r')")"
    fi
  '';

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
