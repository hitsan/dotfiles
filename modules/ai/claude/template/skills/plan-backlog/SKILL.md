---
name: plan-backlog
description: 自律ループの準備を人間と対話しながら進める。SPEC.md・BACKLOG.md・テストを一緒に作り、設定を入れてコミットし、ループの始め方を案内して止まる。blocked の立て直しにも使う。実装はしない。
disable-model-invocation: true
---

# plan-backlog

`/build-next` のループに入る前の準備を、人間をアシストしながら進める。AI は調べて・下書きして・質問して・提案する。決めるのは人間で、各段階で OK をもらってから次へ進む。人間が途中でやめたら、そこまでの成果物を残して止まる。

## 手順

1. **SPEC.md**：無い、雛形のまま、または完了条件が確かめられる形になっていなければ「SPEC.md を一緒に書く」で仕上げる。揃っていれば要点を 3 行で示して確認する。
2. **BACKLOG.md**：既存コードと `tests/` を読み、完了条件を 1 タスク = 1 コミットの大きさに分けて下書きする。
   - 既に `BACKLOG.md` があれば、新しく作らず、done / blocked / todo の件数と `git log` のタスクごとのマージを要約して見せる。`blocked` が残っていれば「blocked を立て直す」を行う。SPEC に追加があれば、その分のタスクだけ下書きに足す。
3. **質問と見直し**：下書きの「質問」を 1 つずつ人間に聞き、答えを SPEC.md か BACKLOG.md に反映する。最後にタスク一覧（ID・やること・after）を表で見せ、粒度・順序の直しを受けて OK をもらう。
4. **テスト**：各タスクの `test:` のテストが無ければ、タスクごとにテストの下書きを見せ、OK をもらってから `tests/` に書く。テストが何を確かめるかを 1 行で添える。人間が「自分で書く」と言ったものは一覧に残す。
5. **設定**：「プロジェクト設定」を入れる。
6. **コミット**：`SPEC.md`・`BACKLOG.md`・`tests/`・`.claude/settings.json` の差分を見せ、OK をもらってコミットする（`/build-next` は作業ツリーが clean でないと止まる）。
7. **案内**：「終了時の案内」を実際の数字で埋めて伝え、止まる。実装コードは書かない。

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

## SPEC.md を一緒に書く

1. 既存コード・README を読み、分かることは先に下書きへ入れておく。
2. 埋まらない項目を 1 つずつ質問する（目的 → やらないこと → 完了条件の順。選択肢が出せるものは選択肢で聞く）。
3. 完了条件は「テストかコマンドで確かめられる形」に言い換えて提案する。曖昧な条件（「使いやすい」など）はそのまま残さない。
4. 下の雛形で `SPEC.md` を書き、全文を見せて OK をもらう。直しが入れば反映して再度確認する。

```markdown
# SPEC

## 目的
<何を作るか。1〜3 行>

## やらないこと
- <範囲外にするもの>

## 完了条件
- <テストかコマンドで確かめられる形で書く。例: `cli summarize sample.csv` が tests/fixtures/expected.json と同じ出力を返す>
```

## blocked を立て直す

1. `blocked` の各行の理由と、関係する差分・テストを読み、原因を「SPEC が曖昧」「テストが誤り」「タスクが大きすぎる」「依存の漏れ」などに分けて示す。
2. 直し方（SPEC の修正、テストの修正、タスクの分割、`after:` の追加）を提案し、OK をもらって反映する。
3. 直したタスクを `todo` に戻し、行末の `fail:` を消す。

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
- サブエージェント（implementer など）からの `tests/` 配下の編集を exit 2 で止める PreToolUse hook。人間と対話しているメインのセッションは止めない。

普段の作業に影響しないよう、グローバルではなくこのループを回すリポジトリにだけ入れる。

## 終了時の案内

```
準備ができました（todo N 件、テスト K 件追加、人間が書くテスト L 件）。

1. 人間が書くテストがあれば書いてコミットする
   - <一覧。無ければこの項目を省く>
2. 設定を読み直すため、新しいセッションでループを始める:
     zellij attach -c autoloop
     claude
     /goal BACKLOG.md の todo が空になるまで /build-next を繰り返す。3 時間たったら止める
   zellij の Ctrl+o は Claude Code と重なるので、Claude Code 側のキーを使うときは先に Ctrl+g でロックする
3. 戻ってきたら、このセッションか新しいセッションで /plan-backlog を呼ぶと、結果の確認と blocked の立て直しを手伝います
```
