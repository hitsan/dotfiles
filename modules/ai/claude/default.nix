{ config, lib, home, ... }:
let
  link = path: config.lib.file.mkOutOfStoreSymlink "${home}/dotfiles/modules/ai/claude/template/${path}";
in
{
  nixpkgs.config.allowUnfreePredicate = pkg:
    builtins.elem (lib.getName pkg) [
      "claude-code"
    ];

  programs.claude-code.enable = true;

  home.file.".claude/AGENTS.md".source = config.lib.file.mkOutOfStoreSymlink "${home}/dotfiles/modules/ai/AGENTS.md";
  home.file.".claude/settings.json".source = link "settings.json";
  home.file.".claude/keybindings.json".source = link "keybindings.json";
  home.file.".claude/statusline-command.sh".source = link "statusline-command.sh";
  home.file.".claude/agents".source = link "agents";
  home.file.".claude/skills/archify".source = link "skills/archify";

  home.sessionVariables.CLAUDE_CODE_PLUGIN_DIRS = lib.concatStringsSep ":" (
    map (mod: "${home}/dotfiles/modules/ai/claude/mods/${mod}") (
      [ "block-cursor" ] ++ lib.optional config.programs.zellij.enable "zellij-status"
    )
  );
}
