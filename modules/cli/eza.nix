{ shell, ... }:
{
  programs.eza.enable = true;
  programs.${shell}.shellAliases = {
    l = "eza";
    ll = "eza -l";
    lt = "eza -T";
  };
}
