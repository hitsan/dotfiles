{ pkgs, shell, user, ... }:
{
  programs = {
    git = {
      enable = true;
      userName = user;
      userEmail = "soledewa2828@gmail.com";
      extraConfig = {
        init.defaultBranch = "main";
      };
    };
  };
  home.packages = with pkgs; [
    git-filter-repo
  ];
  imports = [
    ./gh.nix
    ./lazygit
  ];
}
