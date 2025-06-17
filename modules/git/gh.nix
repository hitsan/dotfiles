{ shell, ... }:
{
  programs = {
    gh = {
      enable = true;
      gitCredentialHelper.enable = true;
      settings = {
        git_protocol = "ssh";
      };
    };
    gh-dash.enable = true;
  };
  programs.${shell}.shellAliases = {
    dash = "gh dash";
  };
}
