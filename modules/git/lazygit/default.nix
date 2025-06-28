{ shell, modules, ... }:
{
  programs.lazygit = {
    enable = true;
  };
  programs.${shell}.shellAliases = {
    lazg = "lazygit";
  };
  home.file.".config/lazygit/config.yml" = {
    source = "${modules}/git/lazygit/config.yml";
  };
}
