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
    gnumake
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
    ./marp
    ./git
    ./ai
    ./docker
    ./lang
    ./xls
    ./verilator
  ];
}
