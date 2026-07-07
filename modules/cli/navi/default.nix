{ pkgs, ... }:
let
  communityCheats = pkgs.fetchFromGitHub {
    owner = "denisidoro";
    repo = "cheats";
    rev = "master";
    sha256 = "sha256-wPsAazAGKPhu0MZfZbZ0POUBEMg95frClAQERTDFXUg=";
  };
in
{
  programs.navi = {
    enable = true;
  };

  xdg.dataFile."navi/cheats/community".source = communityCheats;
}
