{ lib, pkgs, shell, ... }:
{
 nixpkgs.config.allowUnfreePredicate = pkg:
    builtins.elem (lib.getName pkg) [
      "claude-code"
    ];

  home.packages = with pkgs; [
    claude-code
  ];

  programs.${shell} = {
    shellAliases = {
      serena = "claude mcp add serena -- uvx --from git+https://github.com/oraios/serena serena-mcp-server --context ide-assistant --project /home/hitsan/dotfiles/modules";
      };
  };
}
