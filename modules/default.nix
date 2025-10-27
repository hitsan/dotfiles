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
  ];
  programs.${shell} = {
    shellAliases = {
      glow = "glow -p -w $(tput cols)";
    };
  };

  imports = [
    ./shell
    ./zellij
    ./neovim
    ./typst
    ./git
    ./ai
    ./docker
    ./lang
  ];
}
