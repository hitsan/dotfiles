{ pkgs, user, email, ... }:
{
  programs = {
    git = {
      enable = true;
      settings = {
        user = {
          name = user;
          email = email;
        };
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
