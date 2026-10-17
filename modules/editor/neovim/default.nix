{ pkgs, lib, shell, ... }:
let
  zenhan = pkgs.fetchzip {
    url = "https://github.com/iuchim/zenhan/releases/download/v0.0.1/zenhan.zip";
    hash = "sha256-gFpquHucKRMqLmuU7YcUAAggrXYZrRmnqd5At32tmRI=";
  };
in
{
  programs.neovim = {
    enable = true;
  };
  programs.${shell}.shellAliases = {
    v = "nvim";
  };
  home.file.".config/nvim" = {
    source = ./nvim;
    recursive = true;
  };
  home.packages = with pkgs; [
    gopls
    tree-sitter
    nixd
    nixpkgs-fmt
    svls
    typescript-language-server
    vscode-langservers-extracted
  ];
  # Windows 側に置くのは nvim(base.lua) が /mnt/c/tools/zenhan.exe を呼ぶため
  home.activation.zenhan = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ -e /proc/sys/fs/binfmt_misc/WSLInterop ]; then
      run install -Dm755 ${zenhan}/bin64/zenhan.exe /mnt/c/tools/zenhan.exe
    fi
  '';
}
