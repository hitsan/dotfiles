{ pkgs, shell, user, email, ... }:
{
  programs = {
    git = {
      enable = true;
      userName = user;
      userEmail = email;
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
