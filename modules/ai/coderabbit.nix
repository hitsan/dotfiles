{ pkgs, shell, ... }:
let
  coderabbit = pkgs.stdenvNoCC.mkDerivation {
    pname = "coderabbit";
    version = "0.3.4";

    src = pkgs.fetchurl {
      url = "https://cli.coderabbit.ai/releases/0.3.4/coderabbit-linux-x64.zip";
      sha256 = "0jr0smlzc67k74r62g6rl8h9i1xxkhxgfkkb95mb6rgr93j6x6m6";
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
