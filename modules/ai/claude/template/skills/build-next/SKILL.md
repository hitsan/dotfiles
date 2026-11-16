---
name: build-next
description: BACKLOG.md から着手可能なタスクを最大 2 件選び、implementer で並列実装し、タスクごとの PR・テスト・verifier レビューを経てマージし、説明 artifact を更新して通知する。PR に付いた修正の依頼は次のラウンドで拾う。/goal から繰り返し呼ばれる前提。
disable-model-invocation: true
---

# build-next

1 回の呼び出しで 1 ラウンドだけ進める。`/goal` から繰り返し呼ばれる前提なので、ラウンドが終わったら止まる。人間のレビューは待たない。人間はループと並行してタスクごとの PR をレビューし、修正の依頼は次のラウンドで拾う。

## 用語

- **土台**: 今いる branch（`/poc` が切った `feature/<topic>` か `fix/<topic>`）。タスクの PR はすべてここに向ける。
- **タスク branch**: `feature/<topic>-t<n>-<slug>`。修正タスクは `fix/<topic>-t<n>-<slug>`。`<n>` はタスク ID の数字、`<slug>` はやることを英小文字とハイフンで 1〜3 語。
- **レビュー**: 人間がタスクの PR に書くコメント。`OK` で始まればレビュー済み、`修正:` で始まれば修正の依頼。自分の PR は GitHub の Approve ができないため、コメントで判断する。
- **リモート無し**: `git remote` が空のとき。PR を作らず、push もしない。PR の本文に書く内容はマージコミットの本文に書く。

## 手順

1. **確かめる**: 次のどれかに当たれば、伝えて止まる。
   - `SPEC.md`・`BACKLOG.md` が無い、または `.claude/settings.json` に `autoContinueAtUsageLimit` が無い → 「先に `/poc` を呼んでください」
   - 今の branch が `main`（デフォルト branch）→ 「`/poc` が切った branch に切り替えてください」
   - 作業ツリーが clean でない → コミットするよう伝える
2. **修正の依頼を拾う**（リモート無しなら飛ばす）:
   - `gh pr list --base <土台> --state merged --json number,title,comments` で、`修正:` で始まるコメントのうち、その URL が `BACKLOG.md` のどの行の `from:` にも無いものを探す。
   - 見つかったものごとに、todo の先頭にタスクを足す: `- [ ] T<次の番号>: <元タスク ID> の修正: <コメントの内容> — test: <元タスクの test:> — after: - — from: <コメントの URL>`
   - 元タスクの test では確かめられない内容なら、タスクは足さず `質問` に「#<PR> の修正には新しいテストが要る: <内容>」と書く（`tests/` は人間の持ち物）。
   - 足したらコミットする。
3. **選ぶ**: `todo` のうち、`after:` のタスクが全部 `done` にあるものを、修正タスク（`from:` あり）を優先して最大 2 件選ぶ。
   - 前回のラウンドで残った open の PR（`gh pr list --base <土台> --state open`）があれば、そのタスクを先に 5 から続ける。対応する branch が手元に無ければ PR を閉じて失敗扱い。
   - 選べるものが無ければ 9 へ。
4. **実装**: 選んだタスクごとに `implementer` エージェントを **並列で** 起動する（各自 worktree で動く）。渡す内容: タスク行そのまま、`SPEC.md` のパス、タスク branch 名、前回の失敗理由（あれば）。
5. **取り込む**: 返ってきた branch を 1 件ずつ順に処理する。
   1. `git push -u origin <branch>` し、`gh pr create --base <土台> --head <branch> --title "T<n>: <やること>"` で PR を作る。本文は implementer の返した説明（変更・判断したこと・試し方）と `verifier: 確認中`。
   2. `git merge --no-ff <branch> -m "T<n>: <やること> (#<PR>)"`。衝突したら `git merge --abort` して失敗扱い。
   3. プロジェクトのテストを実行する。落ちたら `git reset --keep HEAD~1` でマージを取り消し、失敗扱い。
   4. `verifier` エージェントにタスク行（修正タスクならコメントの内容も）と差分（`git show HEAD`）を渡し、合否を受け取る。NG なら 3 と同様に取り消し、失敗扱い。
   5. OK なら、試し方のコマンドを実行して出力を取り、「説明 artifact」に節を足す。PR の本文を `gh pr edit` で「説明: <artifact の URL>#T<n>」と verifier の判定に書き換える。
   6. `BACKLOG.md` で該当行を `- [x]` にして `done` へ移し、コミットして `git push` する。PR のコミットが土台に入るので、GitHub が PR をマージ済みにする。
   - 失敗扱いのときは `gh pr close <PR> --comment "<理由>"` で PR を閉じる。
6. **失敗を記録**: 失敗したタスクは行末に `— fail: <理由>` を追記する。既に `fail:` がある（2 回目の失敗）なら `blocked` へ移し、理由を残す。コミットして push する。
7. **片付ける**: 処理したタスクの worktree、ローカルとリモートのタスク branch を消す。
8. **知らせる**: `PushNotification` で「T1, T2 をレビューできます（未レビュー N 件）: <説明 artifact の URL>」と送る。未レビューは、土台へのマージ済み PR のうち `OK` か `修正:` で始まるコメントが無いもの。使えなければこのラウンドの報告に含める。
9. **終わりなら PR を作る**: `todo` が空で、土台から `main` への PR がまだ無ければ作る。本文は説明 artifact の URL と、タスクの PR の一覧（`- [x] #101 T1`。未レビューは `[ ]`）。
10. このラウンドの結果（done / 失敗 / blocked / 未レビュー件数）を短く報告して止まる。`todo` が空なら「終了時の案内」を伝える。

## 説明 artifact

ループごとに 1 つ。タスクが done になるたびに節を 1 つ足して公開し直す。人間が PR から飛んで、タスクごとにレビューするためのもの。

- HTML の置き場所は `$(git rev-parse --git-common-dir)/autoloop/explain.html`（コミットしない。作業ツリーも汚さない）。
- 初めて公開したら、`BACKLOG.md` の 1 行目（`# BACKLOG` の次の行）に `説明: <URL>` と書く。2 回目からはその URL に公開し直す。
- 節の id は `T<n>`（PR から `<URL>#T<n>` で飛べるようにする）。中身: やること、PR へのリンク、変更ファイルと増減行数、判断したこと、試し方のコマンドと実際の出力、修正タスクなら元の PR とコメント。
- Artifact ツールが使えなければ作らず、PR の本文に同じ内容を書く。

## ルール

- 親は実装しない。実装は implementer、判定は verifier に任せる。
- `tests/` と `SPEC.md` は人間の持ち物。implementer にも親にも編集させない。
- `main` には push しない。`main` へは人間が PR でマージする。

## プロジェクト側の設定

`/poc` が `.claude/settings.json` に入れる（`autoContinueAtUsageLimit`・`worktree.baseRef`・`tests/` 編集禁止 hook）。

## 終了時の案内

`todo` が空のとき:

```
BACKLOG.md の todo がすべて終わりました（done N 件、blocked M 件、未レビュー K 件）。
- 説明: <説明 artifact の URL>
- main への PR: <URL>
- 未レビューの PR に OK か「修正: ...」をコメントしてください。修正を頼んだら、もう一度ループを回します
- 新しいセッションで /review を呼ぶと、未レビューの PR と未確認の完了条件を一緒に見ます。そのあと /retro で振り返ります
```

blocked・依存待ちで進めないとき:

```
進められるタスクがありません（blocked N 件、依存待ち M 件）。
新しいセッションで /review、続けて /retro を呼ぶと、できあがりの確認と blocked の立て直しを手伝います。
```
