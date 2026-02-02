{ lib, pkgs, shell, modules, ... }:
{
  nixpkgs.config.allowUnfreePredicate = pkg:
    builtins.elem (lib.getName pkg) [
      "claude-code"
    ];

  home.packages = with pkgs; [
    claude-code
  ];

  home.file.".claude/CLAUDE.md".source = "${modules}/ai/claude/template/CLAUDE.md";
  home.file.".claude/agents".source = "${modules}/ai/claude/template/agents";
  home.file.".claude/skills/dataflow-design".source = "${modules}/ai/claude/template/skills/dataflow-design";
  home.file.".claude/skills/state-machine-design".source = "${modules}/ai/claude/template/skills/state-machine-design";
}
