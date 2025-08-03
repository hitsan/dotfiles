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
    just
    devbox
    mise
  ];
  imports = [
    ./claude
    ./gemini
  ];
}
