{ pkgs, ... }:

# let
#   openspec = pkgs.buildNpmPackage {
#     pname = "@fission-ai/openspec";
#     version = "0.13.0";
#
#     src = pkgs.fetchurl {
#       url = "https://registry.npmjs.org/@fission-ai/openspec/-/openspec-0.13.0.tgz";
#       sha256 = "1w1f0b92i32jh5pbwq4mhvrkbdp6l82hk193n383shqjqfiqzl95";
#     };
#
#     npmDepsHash = pkgs.lib.fakeSha256;
#
#     meta = with pkgs.lib; {
#       description = "Spec-Driven Development for AI Coding Assistants";
#       homepage = "https://github.com/fission-ai/openspec";
#       license = licenses.asl20;
#     };
#   };
# in
{
home.packages = with pkgs; [
    nodejs
    #nodePackages.prettier
    nodePackages.fission-ai-openspec
  ];
}
