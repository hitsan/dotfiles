{ pkgs, shell, ... }:
{
  home.packages = with pkgs; [
    ghq
  ];
  programs.${shell} = {
    shellAliases = {
      cg = "z $(ghq list -p | fzf)";
    };
  };
}
