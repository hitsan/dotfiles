# 長時間自律実装スキルの導入計画

AI に長時間自律実装させるためのスキル 2 つとエージェント 2 つを、dotfiles に追加する計画。

- 作業 branch：`feature/autoloop-skills`
- 前提：スキルとエージェントはグローバル（`~/.claude/`）に置き、どのリポジトリからでも呼べるようにする。
- 運用の流れ：人間が `SPEC.md` を書く → `/plan-backlog` で AI が `BACKLOG.md` を作る → 人間が確認して直す → `/goal` から `/build-next` を繰り返す。

## 1. スキル 2 つを追加

どちらも `modules/ai/claude/template/skills/` に置き、`disable-model-invocation: true` を付けて人間が呼んだときだけ動くようにする。

| スキル | やること |
| --- | --- |
| `plan-backlog` | `SPEC.md` を読んで `BACKLOG.md` を作り、そこで止まる。各行に `test:` と `after:` を書き、不明点は質問欄に回す。 |
| `build-next` | 依存の済んだタスクを最大 2 件選び、`implementer` を並列で起動する。親がマージしてテストし、`verifier` がレビューしてから done に移す。衝突したら `merge --abort`、テストが落ちたら `reset --keep HEAD~1`。2 回失敗したら blocked に回す。 |

`modules/ai/claude/default.nix` に `home.file.".claude/skills/<name>"` を 2 行追加する（archify と同じ方式）。

## 2. エージェント 2 つを追加

`template/agents/` はディレクトリごとリンク済みなので、Nix 側の変更は不要。

| エージェント | 設定 | 制約 |
| --- | --- | --- |
| `implementer.md` | `isolation: worktree`、`model: sonnet` | `tests/` と `BACKLOG.md` は編集しない |
| `verifier.md` | tools は `Read, Grep, Glob, Bash`、`model: opus` | レビューのみ。ファイルは編集しない |

## 3. settings はグローバルに入れない

`worktree.baseRef` と、`tests/` の編集を止める PreToolUse hook は、プロジェクトごとの設定。グローバルに入れると、普段の作業でもテストを編集できなくなる。

- 代わりに `/plan-backlog` が最初に、同梱の `settings.json`（`autoContinueAtUsageLimit: true` を含む）をプロジェクトの `.claude/settings.json` にマージする。

## 4. zellij の Ctrl+o との衝突

今回はやらない。ロックモード（`Ctrl+g`）で回避できるため。必要になったら、`modules/terminal/zellij/config.kdl` で `Ctrl o` を別のキーに移す。

## 確認方法

- [x] `home-manager build --flake .` が通る
- [ ] switch したあと、`/plan-backlog` と `/build-next` が補完に出る
- [ ] `/agents` に `implementer` と `verifier` が表示される
- [ ] 捨ててもよいリポジトリで小さな `SPEC.md` を書き、1 周させる（引き継ぎで未検証とされていた点の確認を兼ねる）

## 要判断の点

- [x] `autoContinueAtUsageLimit` はループするプロジェクトにだけ `true` で入れる
