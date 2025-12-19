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

  programs.${shell} = {
    shellAliases = {
      serena = "claude mcp add serena -- uvx --from git+https://github.com/oraios/serena serena-mcp-server --context ide-assistant --project $(pwd)";
      };
  };
}
