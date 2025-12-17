{ lib, pkgs, shell, modules, ... }:
let
  sync_prompt = pkgs.writeShellScriptBin "sync_prompt" ''
    SOURCE_FILE="${modules}/ai/claude/prompt/instructions.md"
    DEST_DIR="''${PWD}/.claude"

    mkdir -p "''${DEST_DIR}"
    cp "''${SOURCE_FILE}" "''${DEST_DIR}/instructions.md"

    echo "✓ Synced to ''${DEST_DIR}/instructions.md"
  '';
in
{
 nixpkgs.config.allowUnfreePredicate = pkg:
    builtins.elem (lib.getName pkg) [
      "claude-code"
    ];

  home.packages = with pkgs; [
    claude-code
    sync_prompt
  ];

  programs.${shell} = {
    shellAliases = {
      serena = "claude mcp add serena -- uvx --from git+https://github.com/oraios/serena serena-mcp-server --context ide-assistant --project $(pwd)";
      };
  };
}
