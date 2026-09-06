{ pkgs, ... }:
{
  fonts.fontconfig.enable = true;
  home.packages = [ pkgs.noto-fonts-cjk-sans ];
  # fontconfig非対応(決め打ちディレクトリ探索のみ)なツール向けに標準フォントディレクトリへも配置する
  home.file.".local/share/fonts/noto-cjk".source =
    "${pkgs.noto-fonts-cjk-sans}/share/fonts/opentype/noto-cjk";
}
