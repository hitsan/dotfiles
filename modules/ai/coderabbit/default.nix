{ stdenv, fetchurl }:
stdenv.mkDerivation {
  pname = "coderabbit";
  version = "0.3.4";

  src = fetchurl {
    url = "https://cli.coderabbit.ai/releases/0.3.4/coderabbit-linux-x64.zip";
    sha256 = "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx";
  };
  unpackPhase = "unzip $src";
  installPhase = ''
    mkdir -p $out/bin
    cp coderabbit $out/bin/coderabbit
    chmod +x $out/bin/coderabbit
  '';
}
