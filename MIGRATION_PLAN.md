# モジュール再編計画書

対象ブランチ: `refactor/submodule-convention`（`main` から派生、直前に `structure-cleanup` 系のコミット済み）

## 目的

`modules/` 配下のカテゴリ分けとサブモジュールの粒度を統一する。

**確定ルール:**
1. `modules/` 直下は役割カテゴリ（12種）。カテゴリの `default.nix` は **imports のみ**（`home.packages` 等を直書きしない）。
2. カテゴリ内の各ツールは「非nixアセットを同梱するなら `foo/` ディレクトリ、純nixなら `foo.nix` フラットファイル」。単一アプリのカテゴリでもアセットが無ければ無理に dir 化しない（例外: `lang/` は下記）。
3. **例外**: `lang/`（gcc, nodejs, python3）はパッケージ列挙だけのカテゴリなので `default.nix` への直書きを維持してよい。
4. 単一アプリのカテゴリ名はドメイン名にする（`neovim`→`editor`, `zellij`→`terminal`, `docker`→`container`, `yazi`→`files`）。カテゴリ名とツール名を同じにしない。

## 最終ツリー

```
modules/
  shell/
    default.nix        # imports
    zsh.nix            # home/shell.nix を移設
    zoxide.nix
    fzf.nix
    pay-respects.nix
  dev/
    default.nix
    just.nix  gnumake.nix  devbox.nix  direnv.nix  act.nix
  cli/
    default.nix
    bat.nix  eza.nix  fd.nix  ripgrep.nix  jq.nix  glow.nix  termscp.nix  vhs.nix
    navi/
      default.nix       # modules/navi/ から移設（community cheats アセットあり→dir）
  lang/
    default.nix         # 変更なし（例外: パッケージ直書き維持）
  editor/
    default.nix
    neovim/
      default.nix
      nvim/             # 既存のLua設定がそのまま入る
  terminal/
    default.nix
    zellij/
      default.nix
      config.kdl / layouts/ / scripts/
  git/
    default.nix
    git.nix             # 新規: git core設定 + git-filter-repo
    gh.nix  ghq.nix  worktrunk.nix
    lazygit/
      default.nix / config.yml
  ai/
    default.nix
    codex.nix           # codex/default.nix から平坦化
    coderabbit.nix      # coderabbit/default.nix から平坦化
    claude/
      default.nix / template/
  container/
    default.nix
    lazydocker.nix      # modules/docker/default.nix から改名移設
  files/
    default.nix
    yazi.nix            # modules/yazi/default.nix から改名移設
  browser/
    default.nix
    chromium.nix         # 既存default.nixから分離

home/
  default.nix           # username, stateVersion, EDITOR, ssh のみ（shell.nix import削除）
```

`navi/` という独立カテゴリは廃止し `cli/navi/` に統合。`docker/` `yazi/` ディレクトリ名は廃止。

## 進め方の原則

- 1カテゴリ = 1コミット。各コミット後に必ず `home-manager build --flake .` が通ることを確認する。
- 論理的にはファイルの移動と`imports`文言の更新のみで、**home-manager生成物の中身は一切変わらない**はず。念のため各コミット後に generation の store hash を直前コミットと比較し、一致することを確認する:
  ```sh
  home-manager build --flake . >/dev/null 2>&1
  readlink -f result
  ```
  ハッシュが変わったら、パッケージ集合やロジックが意図せず変わっていないか確認すること。
- 全コミット後、最終的に `main` の生成物ハッシュと**完全一致**することを比較する（これまでのリファクタと同じ手法）:
  ```sh
  # このブランチ
  home-manager build --flake . >/dev/null 2>&1; AFTER=$(readlink -f result)
  # main
  git stash -u; git checkout main
  home-manager build --flake . >/dev/null 2>&1; BEFORE=$(readlink -f result)
  git checkout refactor/submodule-convention; git stash pop
  echo "before=$BEFORE after=$AFTER"
  [ "$BEFORE" = "$AFTER" ] && echo "一致 OK" || echo "不一致 NG"
  ```
- コミットメッセージは日本語、末尾に `Co-Authored-By: Claude <noreply@anthropic.com>` を付与。

---

## コミット1: `shell/` 新設

`home/shell.nix`（zsh本体）と、`cli/default.nix` に埋もれている zoxide/fzf/pay-respects を統合する。

```sh
mkdir -p modules/shell
git mv home/shell.nix modules/shell/zsh.nix
```

`modules/shell/zsh.nix` の中身は `home/shell.nix` のまま変更不要（引数 `{ shell, home, user, ... }` もそのまま）。

`modules/shell/zoxide.nix`（新規）:
```nix
{ ... }:
{
  programs.zoxide.enable = true;
}
```

`modules/shell/fzf.nix`（新規）:
```nix
{ ... }:
{
  programs.fzf.enable = true;
}
```

`modules/shell/pay-respects.nix`（新規）:
```nix
{ shell, ... }:
{
  programs.pay-respects.enable = true;
  programs.${shell}.initContent = ''
    eval "$(pay-respects zsh --alias f)"
  '';
}
```

`modules/shell/default.nix`（新規）:
```nix
{ ... }:
{
  imports = [
    ./zsh.nix
    ./zoxide.nix
    ./fzf.nix
    ./pay-respects.nix
  ];
}
```

`modules/cli/default.nix` から `fzf.enable`・`zoxide.enable`・`pay-respects.enable`・`initContent`（pay-respects の eval 行）を削除。`fd.enable`・`ripgrep.enable`・`direnv`・shellAliases（l/ll/lt/glow）は**残す**（direnvはコミット2で抜く）。

`home/default.nix` から `imports = [ ./shell.nix ];` を削除。

`modules/default.nix` の `imports` に `./shell` を追加。

**Note**: `pay-respects` は home-manager の `programs.pay-respects.enable` 自体が別途シェル統合フックを生成する可能性がある（現行の生成 `.zshrc` に2つの pay-respects eval 行が見えている）。これは今回のスコープ外の既存の重複なので、動作を変えないよう**そのまま維持**する（直さない）。

---

## コミット2: `dev/` 新設

`cli/default.nix` から act, devbox, gnumake, just, direnv を抜き出す。

```sh
mkdir -p modules/dev
```

`modules/dev/just.nix`:
```nix
{ pkgs, ... }:
{
  home.packages = [ pkgs.just ];
}
```

`modules/dev/gnumake.nix`:
```nix
{ pkgs, ... }:
{
  home.packages = [ pkgs.gnumake ];
}
```

`modules/dev/devbox.nix`:
```nix
{ pkgs, ... }:
{
  home.packages = [ pkgs.devbox ];
}
```

`modules/dev/direnv.nix`:
```nix
{ ... }:
{
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };
}
```

`modules/dev/act.nix`:
```nix
{ pkgs, ... }:
{
  home.packages = [ pkgs.act ];
}
```

`modules/dev/default.nix`:
```nix
{ ... }:
{
  imports = [
    ./just.nix
    ./gnumake.nix
    ./devbox.nix
    ./direnv.nix
    ./act.nix
  ];
}
```

`modules/cli/default.nix` から act/devbox/gnumake/just/direnv の記述を削除。

`modules/default.nix` の `imports` に `./dev` を追加。

---

## コミット3: `cli/` 細分化 + `navi/` 統合

残った cli（bat, eza, fd, ripgrep, jq, glow, termscp, vhs）を1ツール1ファイルに分割し、`modules/navi/` を `cli/navi/` として取り込む。

```sh
git mv modules/navi modules/cli/navi
```

`modules/cli/bat.nix`:
```nix
{ pkgs, ... }:
{
  home.packages = [ pkgs.bat ];
}
```

`modules/cli/eza.nix`:
```nix
{ pkgs, shell, ... }:
{
  home.packages = [ pkgs.eza ];
  programs.${shell}.shellAliases = {
    l = "eza";
    ll = "eza -l";
    lt = "eza -T";
  };
}
```

`modules/cli/fd.nix`:
```nix
{ ... }:
{
  programs.fd.enable = true;
}
```

`modules/cli/ripgrep.nix`:
```nix
{ ... }:
{
  programs.ripgrep.enable = true;
}
```

`modules/cli/jq.nix`:
```nix
{ pkgs, ... }:
{
  home.packages = [ pkgs.jq ];
}
```

`modules/cli/glow.nix`:
```nix
{ pkgs, shell, ... }:
{
  home.packages = [ pkgs.glow ];
  programs.${shell}.shellAliases.glow = "glow -p -w $(tput cols)";
}
```

`modules/cli/termscp.nix`:
```nix
{ pkgs, ... }:
{
  home.packages = [ pkgs.termscp ];
}
```

`modules/cli/vhs.nix`:
```nix
{ pkgs, ... }:
{
  home.packages = [ pkgs.vhs ];
}
```

`modules/cli/default.nix`（imports のみに置き換え）:
```nix
{ ... }:
{
  imports = [
    ./bat.nix
    ./eza.nix
    ./fd.nix
    ./ripgrep.nix
    ./jq.nix
    ./glow.nix
    ./termscp.nix
    ./vhs.nix
    ./navi
  ];
}
```

`modules/default.nix` の `imports` から `./navi` を削除（`./cli` に統合されたため）。

---

## コミット4: `lang/` — 変更なし

このコミットは無し。`modules/lang/default.nix` はそのまま（パッケージ直書きの例外として維持）。

---

## コミット5: `editor/` 新設（`neovim/` を改名・ネスト）

```sh
mkdir -p modules/editor
git mv modules/neovim modules/editor/neovim
```

`modules/editor/default.nix`（新規）:
```nix
{ ... }:
{
  imports = [
    ./neovim
  ];
}
```

`modules/editor/neovim/default.nix` の中身は変更不要。

`modules/default.nix` の `imports` を `./neovim` → `./editor` に変更。

---

## コミット6: `terminal/` 新設（`zellij/` を改名・ネスト）

```sh
mkdir -p modules/terminal
git mv modules/zellij modules/terminal/zellij
```

`modules/terminal/default.nix`（新規）:
```nix
{ ... }:
{
  imports = [
    ./zellij
  ];
}
```

`modules/terminal/zellij/default.nix` の中身は変更不要。

`modules/default.nix` の `imports` を `./zellij` → `./terminal` に変更。

---

## コミット7: `git/` 整理（`git.nix` 切り出し）

`modules/git/git.nix`（新規、`git/default.nix` の programs.git ブロックと git-filter-repo を移設）:
```nix
{ pkgs, user, email, ... }:
{
  programs.git = {
    enable = true;
    settings = {
      user = {
        name = user;
        email = email;
      };
      init.defaultBranch = "main";
    };
  };
  home.packages = [ pkgs.git-filter-repo ];
}
```

`modules/git/default.nix`（imports のみに置き換え）:
```nix
{ ... }:
{
  imports = [
    ./git.nix
    ./gh.nix
    ./ghq.nix
    ./worktrunk.nix
    ./lazygit
  ];
}
```

`gh.nix` / `ghq.nix` / `worktrunk.nix` / `lazygit/` は変更なし。`modules/default.nix` の `./git` エントリも変更不要（ディレクトリ名は変わらない）。

---

## コミット8: `ai/` 整理（`codex`・`coderabbit` を平坦化）

```sh
git mv modules/ai/codex/default.nix modules/ai/codex.nix
rmdir modules/ai/codex
git mv modules/ai/coderabbit/default.nix modules/ai/coderabbit.nix
rmdir modules/ai/coderabbit
```

`modules/ai/default.nix`:
```nix
{ ... }:
{
  imports = [
    ./claude
    ./codex.nix
    ./coderabbit.nix
  ];
}
```

`codex.nix` / `coderabbit.nix` の中身は元の `default.nix` のまま（変更不要）。`claude/` は変更なし。`modules/default.nix` の `./ai` エントリも変更不要。

---

## コミット9: `container/` 新設（`docker/` を改名）

```sh
git mv modules/docker modules/container
git mv modules/container/default.nix modules/container/lazydocker.nix
```

`modules/container/default.nix`（新規）:
```nix
{ ... }:
{
  imports = [
    ./lazydocker.nix
  ];
}
```

`lazydocker.nix` の中身（旧 `docker/default.nix`）は変更不要。

`modules/default.nix` の `imports` を `./docker` → `./container` に変更。

---

## コミット10: `files/` 新設（`yazi/` を改名）

```sh
git mv modules/yazi modules/files
git mv modules/files/default.nix modules/files/yazi.nix
```

`modules/files/default.nix`（新規）:
```nix
{ ... }:
{
  imports = [
    ./yazi.nix
  ];
}
```

`yazi.nix` の中身（旧 `yazi/default.nix`）は変更不要。

`modules/default.nix` の `imports` を `./yazi` → `./files` に変更。

---

## コミット11: `browser/` 整理

`modules/browser/chromium.nix`（`browser/default.nix` の中身をそのまま移設）:
```nix
{ pkgs, ... }:
{
  home.packages = with pkgs; [
    chromium
  ];
}
```

`modules/browser/default.nix`（imports のみに置き換え）:
```nix
{ ... }:
{
  imports = [
    ./chromium.nix
  ];
}
```

`modules/default.nix` の `./browser` エントリは変更不要。

---

## コミット12: `modules/default.nix` 最終形

全コミット終了時点で `modules/default.nix` は以下になっているはず（確認のみ、追加変更不要）:

```nix
{ ... }:
{
  imports = [
    ./shell
    ./terminal
    ./editor
    ./git
    ./ai
    ./container
    ./lang
    ./cli
    ./dev
    ./browser
    ./files
  ];
}
```

---

## コミット13: `CLAUDE.md` 更新（`.claude/CLAUDE.md`）

- 「モジュール構成」セクションの `home/shell.nix` の説明を削除（zsh設定は `modules/shell/` に移動した旨を明記）。
- 「モジュール一覧」テーブルを新カテゴリで全面更新:

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

- 「新モジュールを追加するとき」のテンプレート例に、`foo.nix`（純nix）と `foo/`（アセット同梱）の使い分けルールを1行追記。

---

## 最終検証

1. 全13コミット後、`home-manager build --flake .` が通ること。
2. 上記の hash 比較スクリプトで `main` の生成物と完全一致すること。
3. `home-manager switch --flake .` を適用し、実環境で以下が生きていることを確認:
   - `zsh` 起動（PS1・alias・direnv hook）
   - `nvim`, `zellij`, `yazi`, `lazydocker`, `chromium` の起動
   - `gh`, `lazygit`, `ghq`, `worktrunk` の動作
   - `claude` CLI・statusline・claude-tab-status hook
4. マージ前に `git log --oneline main..refactor/submodule-convention` でコミット粒度を最終確認。
