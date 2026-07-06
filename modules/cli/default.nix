{ pkgs, shell, ... }:
{
  home.packages = with pkgs; [
    act
    bat
    devbox
    eza
    glow
    gnumake
    jq
    just
    termscp
    vhs
  ];
  programs = {
    fd.enable = true;
    fzf.enable = true;
    zoxide.enable = true;
    ripgrep.enable = true;
    pay-respects.enable = true;
    direnv = {
      enable = true;
      nix-direnv.enable = true;
    };

    ${shell} = {
      initContent = ''
        eval "$(pay-respects zsh --alias f)"
      '';
      shellAliases = {
        l = "eza";
        ll = "eza -l";
        lt = "eza -T";
        glow = "glow -p -w $(tput cols)";
      };
    };
  };
}
