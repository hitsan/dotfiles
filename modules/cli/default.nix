{ pkgs, shell, ... }:
{
  home.packages = with pkgs; [
    act
    bat
    eza
    jq
    vhs
  ];
  programs = {
    fd.enable = true;
    fzf.enable = true;
    zoxide.enable = true;
    ripgrep.enable = true;
    pay-respects.enable = true;

    ${shell} = {
      initContent = ''
        eval "$(pay-respects zsh --alias f)"
      '';
      shellAliases = {
        l = "eza";
        ll = "eza -l";
        lt = "eza -T";
      };
    };
  };
}
