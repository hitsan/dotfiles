{ pkgs, ... }:
{
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

  # Enable font configuration for proper CJK font handling
  fonts.fontconfig.enable = true;
  
  # Explicit font configuration
  home.file.".config/fontconfig/fonts.conf".text = ''
    <?xml version="1.0"?>
    <!DOCTYPE fontconfig SYSTEM "fonts.dtd">
    <fontconfig>
      <alias>
        <family>serif</family>
        <prefer>
          <family>Noto Serif CJK JP</family>
          <family>Source Han Serif</family>
          <family>IPAMincho</family>
        </prefer>
      </alias>
      <alias>
        <family>sans-serif</family>
        <prefer>
          <family>Noto Sans CJK JP</family>
          <family>Source Han Sans</family>
          <family>IPAGothic</family>
        </prefer>
      </alias>
    </fontconfig>
  '';
}
