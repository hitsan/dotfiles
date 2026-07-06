{ pkgs, shell, ... }:
{
  home.packages = with pkgs; [
    worktrunk
  ];
  programs.${shell}.initContent = ''
    eval "$(wt config shell init ${shell})"
  '';
  xdg.configFile."worktrunk/config.toml".text = ''
    worktree-path = "~/worktrees/{{ owner }}/{{ repo }}/{{ branch | sanitize }}"
  '';
}
