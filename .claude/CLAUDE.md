# dotfiles

Nix Flakes + Home Manager で管理する dotfiles（x86_64-linux / WSL2）。

## 主要コマンド

```sh
# 設定を適用
home-manager switch --flake .

# ビルドのみ（適用しない）
home-manager build --flake .

# flake の更新
nix flake update
```

## アーキテクチャ

### inputs
| input | 用途 |
|-------|------|
| `nixpkgs-unstable` | パッケージ |
| `home-manager` | ユーザー設定管理 |

### extraSpecialArgs（全モジュールで利用可能）
| 変数 | 値 |
|------|-----|
| `user` | `hitsan` |
| `email` | GitHub noreply アドレス |
| `home` | `/home/hitsan` |
| `shell` | `zsh` |

### モジュール構成
```
home/default.nix   # ユーザー設定（username, stateVersion, EDITOR, ssh）
modules/default.nix  # 全モジュールを import するだけの集約ファイル
modules/<name>/    # 各ツールの設定（下記参照）
```

zsh 設定（zsh本体・zoxide・fzf・pay-respects）は `modules/shell/` に移動した。

## モジュール一覧

| ディレクトリ | 内容 |
|-------------|------|
| `shell/` | zsh, zoxide, fzf, pay-respects |
| `dev/` | just, gnumake, devbox, direnv, act |
| `cli/` | bat, eza, fd, ripgrep, jq, glow, termscp, vhs, navi |
| `lang/` | プログラミング言語ランタイム |
| `editor/` | neovim |
| `terminal/` | zellij |
| `git/` | git, gh, ghq, lazygit, worktrunk |
| `ai/` | claude, codex, coderabbit |
| `container/` | lazydocker |
| `files/` | yazi |
| `browser/` | chromium |

## 新モジュールを追加するとき

1. `modules/<name>/default.nix` を作成（非nixアセットを同梱するなら `foo/` ディレクトリ、純nixなら `foo.nix` フラットファイル）
2. `modules/default.nix` の `imports` に `./name` を追加
3. モジュール引数に必要な `extraSpecialArgs` 変数を宣言する

```nix
# modules/<name>/default.nix のテンプレート
{ pkgs, shell, ... }:
{
  home.packages = with pkgs; [ ... ];
  programs.${shell}.shellAliases = { ... };
}
```

## Git ワークフロー

- 実装作業で `main` を直接編集しない。作業用の branch を切ってから編集する
  （`git checkout -b feature/<topic>`）。
- 複数セッションで並列に作業する場合は branch だけでなく
  `git worktree add ../dotfiles-<topic> -b feature/<topic>` で作業ディレクトリ
  も分離する。理由: 同じ作業ディレクトリを共有すると、別セッションの
  未コミット変更やコミットタイミングと衝突するため。
- 作業完了後は PR 経由でマージし、worktree を使った場合は
  `git worktree remove` とローカル branch 削除で片付けてから `main` を
  最新化する。

## 注意点

- `home.stateVersion` は変更しない（Home Manager の互換性に影響）
- パッケージ追加は `home.packages` より `programs.<name>.enable` を優先する
- `shell` 変数を使って `programs.${shell}` に設定を書くとシェル非依存になる
