{ lib, pkgs, shell, ... }:
{
  nixpkgs.config.allowUnfreePredicate = pkg:
    builtins.elem (lib.getName pkg) [
      "claude-code"
    ];

  home.packages = with pkgs; [
    claude-code
  ];

  home.file.".claude/CLAUDE.md".source = ./template/CLAUDE.md;
  home.file.".claude/settings.json".source = ./template/settings.json;
  home.file.".claude/statusline-command.sh" = {
    source = ./template/statusline-command.sh;
    executable = true;
  };
  home.file.".claude/agents".source = ./template/agents;
  home.file.".claude/skills/design".source = ./template/skills/design;
  home.file.".claude/skills/arch".source = ./template/skills/arch;
  home.file.".claude/skills/modeling".source = ./template/skills/modeling;
  home.file.".claude/skills/zellij-send".source = ./template/skills/zellij-send;
  home.file.".claude/skills/html-report".source = ./template/skills/html-report;
}
