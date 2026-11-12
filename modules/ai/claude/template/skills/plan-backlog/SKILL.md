---
name: plan-backlog
description: SPEC.md を読んでタスク分解した BACKLOG.md を作り、そこで止まる。実装はしない。
disable-model-invocation: true
---

# plan-backlog

リポジトリ直下の `SPEC.md` から `BACKLOG.md` を作る。人間が確認・修正してから `/build-next` に渡すための下書き。

## 手順

0. ループ用のプロジェクト設定を入れる（後述「プロジェクト設定」）。
1. `SPEC.md` を読む（目的・やらないこと・完了条件）。無ければ作成を促して終了する。
2. 既存コードと `tests/` を読み、現状を把握する。
3. 完了条件を、1 タスク = 1 コミットで終わる大きさに分解する。
4. 下の形式で `BACKLOG.md` を書く（既にあれば上書きせず、差分を提案して止まる）。
5. 書き終えたら止まる。コードもテストも書かない。設定を変えた場合は、`/goal` を新しいセッションで始めるよう伝える。

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
