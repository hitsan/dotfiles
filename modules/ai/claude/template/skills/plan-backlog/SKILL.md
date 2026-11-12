---
name: plan-backlog
description: SPEC.md を読んでタスク分解した BACKLOG.md を作り、そこで止まる。実装はしない。
disable-model-invocation: true
---

# plan-backlog

リポジトリ直下の `SPEC.md` から `BACKLOG.md` を作る。人間が確認・修正してから `/build-next` に渡すための下書き。

## 手順

0. ループ用のプロジェクト設定を入れる（後述「プロジェクト設定」）。
1. `SPEC.md` を読む（目的・やらないこと・完了条件）。無ければ下の「SPEC.md の雛形」で `SPEC.md` を作り、「埋めたらもう一度 `/plan-backlog` を呼んでください」と伝えて終了する。
2. 既存コードと `tests/` を読み、現状を把握する。
3. 完了条件を、1 タスク = 1 コミットで終わる大きさに分解する。
4. 下の形式で `BACKLOG.md` を書く（既にあれば上書きせず、差分を提案して止まる）。
5. 各タスクの `test:` に書いたテストが既にあるか確かめ、無いものを「人間が書くテスト」として一覧にする（`tests/` は AI から編集できない）。
6. 下の「終了時の案内」を、実際のタスク数・質問・未作成テストで埋めて伝え、止まる。コードもテストも書かない。

## タスク行のルール

- ID は `T1`, `T2`, ... の連番。
- `test:` に、完了を確かめるテスト（テストファイル名・テスト名、または実行コマンドと期待結果）を書く。確かめられないタスクは作らない。
- `after:` に、先に done になっている必要があるタスク ID を書く。無ければ `-`。
- 並列実行されるため、同じファイルを触るタスク同士は `after:` で順序を付ける。
- SPEC から判断できない点は推測で埋めず「質問」に書く。

## BACKLOG.md の形式

```markdown
# BACKLOG

## todo
- [ ] T1: <やること> — test: <確かめるテスト> — after: -
- [ ] T2: <やること> — test: <確かめるテスト> — after: T1

## done

## blocked

## 質問
- <SPEC から判断できない点>
```

## プロジェクト設定

このスキルのディレクトリにある `settings.json` を、リポジトリの `.claude/settings.json` にマージする。既存の設定は残し、`hooks.PreToolUse` は同じものが無ければ追加する（何度実行しても同じ結果になる）。

```sh
tpl=<このスキルのディレクトリ>/settings.json
mkdir -p .claude && [ -f .claude/settings.json ] || echo '{}' > .claude/settings.json
jq -s '.[0] as $cur | .[1] as $tpl | ($cur * ($tpl | del(.hooks))) | .hooks.PreToolUse = (($cur.hooks.PreToolUse // []) as $p | $p + ($tpl.hooks.PreToolUse | map(select(. as $h | $p | index([$h]) | not))))' \
  .claude/settings.json "$tpl" > .claude/settings.json.tmp && mv .claude/settings.json.tmp .claude/settings.json
```

入る設定:
- `autoContinueAtUsageLimit: true` — 使用量上限で止まっても、リセット後に自動で続ける。
- `worktree.baseRef: "head"` — implementer の worktree を今の HEAD（直前のラウンドで done にしたコミットを含む）から切る。
- `tests/` 配下への編集を exit 2 で止める PreToolUse hook。

普段の作業に影響しないよう、グローバルではなくこのループを回すリポジトリにだけ入れる。

## SPEC.md の雛形

```markdown
# SPEC

## 目的
<何を作るか。1〜3 行>

## やらないこと
- <範囲外にするもの>

## 完了条件
- <テストかコマンドで確かめられる形で書く。例: `cli summarize sample.csv` が tests/fixtures/expected.json と同じ出力を返す>
```

## 終了時の案内

```
BACKLOG.md を作りました（todo N 件、質問 M 件）。次にやること:

1. BACKLOG.md の「質問」に答え、タスクの粒度・順序・test: を直す
2. 次のテストを tests/ に書く（AI は tests/ を編集できません）
   - <未作成のテスト一覧。無ければ「なし」>
3. SPEC.md・BACKLOG.md・tests/・.claude/settings.json をコミットする（作業ツリーが clean でないと /build-next は止まります）
4. 設定を読み直すため、新しいセッションでループを始める:
     zellij attach -c autoloop
     claude
     /goal BACKLOG.md の todo が空になるまで /build-next を繰り返す。3 時間たったら止める
   zellij の Ctrl+o は Claude Code と重なるので、Claude Code 側のキーを使うときは先に Ctrl+g でロックする
5. 戻ってきたら BACKLOG.md の done / blocked を確認する
```
