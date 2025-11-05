{ stdenv, fetchurl, unzip }:
stdenv.mkDerivation {
  pname = "coderabbit";
  version = "0.3.4";

  src = fetchurl {
    url = "https://cli.coderabbit.ai/releases/0.3.4/coderabbit-linux-x64.zip";
    sha256 = "0jr0smlzc67k74r62g6rl8h9i1xxkhxgfkkb95mb6rgr93j6x6m6";
  };

  nativeBuildInputs = [ unzip ];

  unpackPhase = ''
    unzip $src
  '';

  installPhase = ''
    mkdir -p $out/bin
    cp coderabbit $out/bin/coderabbit
    chmod +x $out/bin/coderabbit
  '';
}
