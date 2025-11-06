{ pkgs, ... }:
let
  openspec = pkgs.writeShellScriptBin "openspec" ''
    export PATH="${pkgs.nodejs}/bin:$PATH"
    exec ${pkgs.nodejs}/bin/npx -y @fission-ai/openspec@0.14.0 "$@"
  '';
in
{
  home.packages = [
    openspec
  ];
}
