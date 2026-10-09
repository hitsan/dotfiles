{ pkgs, shell, ... }:
let
  coderabbit = pkgs.stdenvNoCC.mkDerivation {
    pname = "coderabbit";
    version = "0.9.0";

    src = pkgs.fetchurl {
      url = "https://cli.coderabbit.ai/releases/0.9.0/coderabbit-linux-x64.zip";
      hash = "sha256-VuTJnenREQbD5r8xA0hk2490bLl8nq+UcK3PpkYdpm8=";
    };

    nativeBuildInputs = [ pkgs.unzip ];

    dontBuild = true;
    dontStrip = true;
    dontPatchELF = true;
    dontPatchShebangs = true;

    sourceRoot = ".";

    installPhase = ''
      runHook preInstall
      install -Dm755 coderabbit $out/bin/coderabbit
      runHook postInstall
    '';
  };
in
{
  home.packages = [ coderabbit ];
  programs.${shell}.shellAliases = {
    cr = "coderabbit";
  };

}
