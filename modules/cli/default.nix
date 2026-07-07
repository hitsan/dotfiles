{ pkgs, shell, ... }:
{
  home.packages = with pkgs; [
    bat
    eza
    glow
    jq
    termscp
    vhs
  ];
  programs = {
    fd.enable = true;
    ripgrep.enable = true;

    ${shell} = {
      shellAliases = {
        l = "eza";
        ll = "eza -l";
        lt = "eza -T";
        glow = "glow -p -w $(tput cols)";
      };
    };
  };
}
