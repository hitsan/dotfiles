{ shell, modules, ... }:
{
  programs.lazygit = {
    enable = true;
  };
  home.file.".config/lazygit/config.yml" = {
    source = "${modules}/git/lazygit/config.yml";
  };
}
