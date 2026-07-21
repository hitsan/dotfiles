{ pkgs, shell, ... }:
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

  programs.${shell} = {
    shellAliases = {
      zel = "zellij";
      zls = "zellij ls";
      zka = "zellij ka -y";
      zda = "zellij da -y";
      zsf = "zellij -l strider";
    };
    initContent = ''
      function precmd() {
        local branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
        local host=$(hostname)
        local title="$host"
        if [[ -n "$branch" ]]; then
          title+="[$branch]"
        fi
        title+=":%~"
        print -Pn "\e]2;$title\a"
      }
    '';
  };
  home.file.".config/zellij/config.kdl".source = ./config.kdl;
  home.file.".config/zellij/layouts/compact.kdl".source = ./layouts/compact.kdl;
  home.file.".config/zellij/scripts/claude-tab-status.sh" = {
    source = ./scripts/claude-tab-status.sh;
    executable = true;
  };
  home.file.".config/zellij/scripts/zellij-send.sh" = {
    source = ./scripts/zellij-send.sh;
    executable = true;
  };
}
