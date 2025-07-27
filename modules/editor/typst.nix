{ pkgs, ... }:
{
  fonts.fontconfig.enable = true;
  home.packages = with pkgs; [
    typst
    # Japanese fonts for proper PDF rendering
    noto-fonts-cjk-sans
    noto-fonts-cjk-serif
    # Additional fonts that might help with rendering
    noto-fonts
    ipafont
    source-han-serif
    source-han-sans
  ];
}
