{ lib, pkgs, shell, modules, ... }:
let
  sync_prompt = pkgs.writeShellScriptBin "sync_prompt" ''
    SOURCE_DIR="${modules}/ai/claude/template/.claude"
    DEST_DIR="''${PWD}/.claude"

    # Create directories
    mkdir -p "''${DEST_DIR}/agents"

    # Update CLAUDE.md (overwrite)
    cp "''${SOURCE_DIR}/CLAUDE.md" "''${DEST_DIR}/"

    # Update template agents (overwrite only template files)
    for agent in "''${SOURCE_DIR}/agents/"*.md; do
      if [ -f "$agent" ]; then
        agent_name=$(basename "$agent")
        cp "$agent" "''${DEST_DIR}/agents/$agent_name"
      fi
    done

    echo "✓ Synced Claude templates to ''${DEST_DIR}"
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
