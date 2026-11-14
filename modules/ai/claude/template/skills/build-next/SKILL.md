---
name: build-next
description: BACKLOG.md から着手可能なタスクを最大 2 件選び、implementer で並列実装し、マージ・テスト・verifier レビューを経て done に移す。/goal から繰り返し呼ばれる前提。
disable-model-invocation: true
---

# build-next

1 回の呼び出しで 1 ラウンドだけ進める。`/goal` から繰り返し呼ばれる前提なので、ラウンドが終わったら止まる。

## 手順

1. `SPEC.md` と `BACKLOG.md` を読む。どちらかが無い、または `.claude/settings.json` に `autoContinueAtUsageLimit` が無ければ、「先に `/poc` を呼んでください」と伝えて止まる。作業ツリーが clean でなければ、コミットするよう伝えて止まる。
2. `todo` のうち、`after:` のタスクが全部 `done` にあるものを上から最大 2 件選ぶ。
   - 選べるものが無ければ、下の「終了時の案内」を伝えて止まる。
3. 選んだタスクごとに `implementer` エージェントを **並列で** 起動する（各自 worktree で動く）。渡す内容: タスク行そのまま、`SPEC.md` のパス、前回の失敗理由（あれば）。
4. 返ってきた branch を、親が 1 件ずつ順に取り込む。
   1. `git merge --no-ff <branch>`。衝突したら `git merge --abort` して、そのタスクは失敗扱い。
   2. プロジェクトのテストを実行する。落ちたら `git reset --keep HEAD~1` でマージを取り消し、失敗扱い。
   3. `verifier` エージェントにタスク行と差分（`git show HEAD`）を渡し、合否を受け取る。NG なら 2 と同様に取り消し、失敗扱い。
   4. OK なら `BACKLOG.md` で該当行を `- [x]` にして `done` へ移し、コミットする。
5. 失敗したタスクは行末に `— fail: <理由>` を追記する。既に `fail:` がある（2 回目の失敗）なら `blocked` へ移し、理由を残す。
6. 取り込み済み・不要になった worktree と branch を片付ける。
7. このラウンドの結果（done / 失敗 / blocked）を短く報告して止まる。

## ルール

- 親は実装しない。実装は implementer、判定は verifier に任せる。
- `tests/` と `SPEC.md` は人間の持ち物。implementer にも親にも編集させない。

## プロジェクト側の設定

`/poc` が `.claude/settings.json` に入れる（`autoContinueAtUsageLimit`・`worktree.baseRef`・`tests/` 編集禁止 hook）。

## 終了時の案内

`todo` が空のとき:

```
BACKLOG.md の todo がすべて終わりました（done N 件、blocked M 件）。
- git log --oneline でタスクごとのマージを確認してください
- blocked があれば /poc で立て直しを手伝います
```

blocked・依存待ちで進めないとき:

```
進められるタスクがありません（blocked N 件、依存待ち M 件）。
新しいセッションで /poc を呼ぶと、blocked の原因の切り分けと直しを手伝います。
```
