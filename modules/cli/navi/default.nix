{ pkgs, ... }:
let
  communityCheats = pkgs.fetchFromGitHub {
    owner = "denisidoro";
    repo = "cheats";
    rev = "1339965e9615ce00174cc308a41279d9c59aa75f";
    sha256 = "sha256-wPsAazAGKPhu0MZfZbZ0POUBEMg95frClAQERTDFXUg=";
  };
in
{
  programs.navi = {
    enable = true;
  };

  xdg.dataFile."navi/cheats/community".source = communityCheats;
}
