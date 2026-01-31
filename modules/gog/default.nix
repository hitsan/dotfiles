{ pkgs, lib, modules, inputs, ... }:
let
  gogcli = pkgs.buildGoModule {
    pname = "gogcli";
    version = "unstable-${inputs.gogcli.rev or "unknown"}";
    src = inputs.gogcli;
    vendorHash = "sha256-nig3GI7eM1XRtIoAh1qH+9PxPPGynl01dCZ2ppyhmzU=";
  };
in
{
  home.packages = [
    gogcli
  ];

  # credentials.json は Nix store に入れない方針
}
