{ shell, ... }:
{
  programs.pay-respects.enable = true;
  programs.${shell}.initContent = ''
    eval "$(pay-respects zsh --alias f)"
  '';
}
