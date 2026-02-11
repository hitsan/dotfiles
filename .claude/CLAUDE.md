# dotfiles

Nix Flakes + Home Manager で管理する dotfiles リポジトリ（x86_64-linux / WSL2）。

## ディレクトリ構成

```
.
├── flake.nix              # エントリポイント（nixpkgs-unstable, home-manager）
├── flake.lock
├── home/
│   ├── default.nix        # ユーザー設定（username, EDITOR, ssh）
│   └── shell.nix          # シェル共通設定（zsh aliases）
└── modules/
    ├── default.nix        # 全モジュールの import 集約
    ├── ai/                # AI ツール（claude, coderabbit, codex, gemini）
    ├── browser/           # ブラウザ
    ├── cli/               # CLI ユーティリティ
    ├── docker/            # Docker
    ├── git/               # git, gh, ghq, lazygit
    ├── lang/              # プログラミング言語
    ├── marp/              # Marp（スライド）
    ├── navi/              # navi（チートシート）
    ├── neovim/            # Neovim + Lua プラグイン設定
    │   └── nvim/          #   init.lua, lua/base.lua, lua/plugins/
    ├── shell/             # シェル・ターミナル（alacritty）
    ├── typst/             # Typst（組版）
    ├── verilator/         # Verilator（HDL シミュレータ）
    ├── yazi/              # yazi（ファイルマネージャ）
    └── zellij/            # Zellij（ターミナルマルチプレクサ）
```

## 適用方法

```sh
home-manager switch --flake .
```

## 変更時の注意

- 各 `modules/<name>/default.nix` が Home Manager モジュール単位
- `flake.nix` の `extraSpecialArgs` で `user`, `email`, `home`, `shell`, `modules` を各モジュールに渡している
- シェルは `zsh` がデフォルト
