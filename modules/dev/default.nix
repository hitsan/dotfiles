{ pkgs, shell, ... }:
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
  programs.${shell} = {
    shellAliases = {
      glow = "glow -p -w $(tput cols)";
    };
  };

  imports = [
    ./claude
    ./gemini
  ];
}
