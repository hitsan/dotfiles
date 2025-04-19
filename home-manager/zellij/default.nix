{ config, pkgs, shell, home_path, ... }:
{
  home.packages = [
    pkgs.zellij
  ];

  programs.zellij = {
    enableZshIntegration = true;
    settings = {
      "zellij.default" = {
        "theme" = "dark";
        "layout" = "default";
      };
    };
  };

  # home.file.".config/zellij/config.kdl".source = ./config.kdl;
  programs.${shell} = {
    shellAliases = {
      zel = "zellij";
      zls = "zellij ls";
      zka = "zellij ka -y";
      zda = "zellij da -y";
    };
    initExtra = ''
      function precmd() {
        local branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
        local host=$(hostname)
        local title=" @$host"
        if [[ -n "$branch" ]]; then
          title+=" [$branch]"
        fi
        title+=" %~"
        print -Pn "\e]2;$title\a"
      }
    '';
  };
  home.file.".config/zellij/config.kdl".source = home_path + "/zellij/config.kdl";
}
