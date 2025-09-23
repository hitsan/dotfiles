{ pkgs, ... }:
{
  programs = {
    direnv = {
      enable = true;
      enableBashIntegration = true;
      nix-direnv.enable = true;
    };
  };
  home.packages = with pkgs; [
    devbox
    glow
    just
    mise
  ];
  imports = [
    ./claude
    ./gemini
  ];
}
