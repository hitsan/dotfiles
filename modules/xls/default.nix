{ lib, pkgs, ... }:
let
  version = "0.0.0-9093-g66f29e67b";

  xls = pkgs.stdenv.mkDerivation {
    pname = "xls";
    version = version;

    src = pkgs.fetchurl {
      url = "https://github.com/google/xls/releases/download/v${version}/xls-v${version}-linux-x64.tar.gz";
      hash = "sha256-jmmBmtyu7R34shEw4zimaJa9Asof/KspGkQBCMBizKA=";
    };

    sourceRoot = ".";

    installPhase = ''
      runHook preInstall

      mkdir -p $out/bin

      # Copy all executables to bin directory
      find . -type f -executable -name "*_main" -exec cp {} $out/bin/ \;

      # Make sure all binaries are executable
      chmod +x $out/bin/*

      runHook postInstall
    '';

    meta = with lib; {
      description = "XLS: Accelerated HW Synthesis";
      homepage = "https://github.com/google/xls";
      license = licenses.asl20;
      platforms = platforms.linux;
      maintainers = [ ];
    };
  };
in
{
  home.packages = [ xls ];
}
