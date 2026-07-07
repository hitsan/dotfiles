# dotfiles

Nix Flakes + Home Manager で管理する dotfiles（x86_64-linux / WSL2）。

## セットアップ

前提: Nix（flakes 有効化済み）

```sh
git clone git@github.com:hitsan/dotfiles.git
cd dotfiles
home-manager switch --flake .
```

## 主要コマンド

```sh
# 設定を適用
home-manager switch --flake .

# ビルドのみ（適用しない）
home-manager build --flake .

# flake の更新
nix flake update
```

## Tips

### zellij: zjstatus / zjstatus-hints の権限

`load_plugins` でバックグラウンド起動されるため権限プロンプトが表示されず、
無許可のまま永久に無反応になることがある。新しいマシンでは以下を一度手動実行して許可する。

```sh
zellij action launch-plugin "https://github.com/dj95/zjstatus/releases/latest/download/zjstatus.wasm"
zellij action launch-plugin "https://github.com/b0o/zjstatus-hints/releases/latest/download/zjstatus-hints.wasm"
```

起動したフローティングペインで許可(y)すると `~/.cache/zellij/permissions.kdl` に記録される。

必要な権限:

| plugin | permissions |
|---|---|
| zjstatus | RunCommands, ChangeApplicationState, ReadApplicationState |
| zjstatus-hints | ReadApplicationState, MessageAndLaunchOtherPlugins |
