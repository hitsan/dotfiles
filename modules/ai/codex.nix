{ config, home, ... }:
{
  programs.codex.enable = true;

  home.file.".codex/AGENTS.md".source = config.lib.file.mkOutOfStoreSymlink "${home}/dotfiles/modules/ai/AGENTS.md";
}
