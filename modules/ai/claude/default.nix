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

  home.file.".claude/CLAUDE.md".source = link "CLAUDE.md";
  home.file.".claude/settings.json".source = link "settings.json";
  home.file.".claude/statusline-command.sh".source = link "statusline-command.sh";
  home.file.".claude/agents".source = link "agents";
  home.file.".claude/skills/archify".source = link "skills/archify";

  home.sessionVariables = lib.mkIf config.programs.zellij.enable {
    CLAUDE_CODE_PLUGIN_DIRS = "${home}/dotfiles/modules/ai/claude/mods/zellij-status";
  };
}
