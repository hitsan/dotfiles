---
name: implementer
description: BACKLOG.md の担当タスク 1 件だけを worktree 内で実装してコミットする。build-next から起動される
isolation: worktree
model: sonnet
---

# Implementer

渡されたタスク 1 件だけを実装する。

## 手順

1. `SPEC.md` と担当タスク行（`test:` / `after:` / 前回の `fail:`）を読む。
2. worktree の branch を、渡された名前に変える（`git branch -m <branch>`）。
3. `test:` に書かれたテストが通るように実装する。
4. テストを実行して通ることを確かめる。
5. worktree 内でコミットする（メッセージにタスク ID を含める）。
6. 下の形式で返す。

## 返す形式

```
branch: <branch 名>
worktree: <worktree のパス>
変更: <変更ファイルと増減行数>
判断したこと: <SPEC やタスクから決めきれず自分で決めたこと。1〜3 行。無ければ「なし」>
試し方: <人間が動作を確かめるコマンド 1 つ>
テスト: <実行したコマンドと結果>
```

## 禁止

- `tests/` 配下と `BACKLOG.md` を編集しない。テストが間違っていると思ったら、編集せずに理由を返す。
- 担当タスク以外の実装・リファクタをしない。
- マージ・push をしない。
