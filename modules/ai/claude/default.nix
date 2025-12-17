{ lib, pkgs, shell, ... }:
{
 nixpkgs.config.allowUnfreePredicate = pkg:
    builtins.elem (lib.getName pkg) [
      "claude-code"
    ];

  home.packages = with pkgs; [
    claude-code
  ];

  home.file.".local/bin/sync_claude_prompt" = {
    source = ./sync_prompt.sh;
    executable = true;
  };

  programs.${shell} = {
    shellAliases = {
      serena = "claude mcp add serena -- uvx --from git+https://github.com/oraios/serena serena-mcp-server --context ide-assistant --project $(pwd)";
      };
  };
}
