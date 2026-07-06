{ shell, ... }:
{
  programs.lazygit = {
    enable = true;
  };
  home.file.".config/lazygit/config.yml" = {
    source = ./config.yml;
  };
}
