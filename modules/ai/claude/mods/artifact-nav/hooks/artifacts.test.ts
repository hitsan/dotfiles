import { expect, test } from 'claude-code/testing'

import { extractUrl, record, titleOf, view } from './artifacts'

test('結果の中から artifact の URL を拾う', () => {
  expect(extractUrl({ text: 'Published x at https://claude.ai/artifact/TpEoqEJ (Version 2)' })).toBe('https://claude.ai/artifact/TpEoqEJ')
  expect(extractUrl({ frame: { url: 'https://claude.ai/code/artifact/ab-12' } })).toBe('https://claude.ai/code/artifact/ab-12')
  expect(extractUrl({ text: 'nothing' })).toBeUndefined()
})

test('タイトルは <title>、無ければファイル名', () => {
  expect(titleOf('<title>autoloop の使い方</title><style>', '/s/guide.html')).toBe('autoloop の使い方')
  expect(titleOf('<p>x</p>', '/s/guide.html')).toBe('guide.html')
})

test('同じ URL は 1 件にまとめ、タイトルと時刻を更新する', () => {
  let db = record({}, 's1', { label: 'first', cwd: '/r' }, { url: 'u1', title: 'A', at: 1 })
  db = record(db, 's1', { label: 'ignored', cwd: '/r' }, { url: 'u1', title: 'A2', at: 2 })
  db = record(db, 's1', { label: 'ignored', cwd: '/r' }, { url: 'u2', title: 'B', at: 3 })
  expect(db.s1!.label).toBe('first')
  expect(db.s1!.artifacts).toEqual([{ url: 'u1', title: 'A2', at: 2 }, { url: 'u2', title: 'B', at: 3 }])
})

test('今のセッションは新しい順、過去は最後に作った順で 10 件まで', () => {
  let db = {}
  for (let i = 0; i < 12; i++) db = record(db, `p${i}`, { label: `L${i}`, cwd: '/r' }, { url: `u${i}`, title: `T${i}`, at: i })
  db = record(db, 'now', { label: 'N', cwd: '/r' }, { url: 'a', title: 'old', at: 100 })
  db = record(db, 'now', { label: 'N', cwd: '/r' }, { url: 'b', title: 'new', at: 101 })
  const v = view(db, 'now')
  expect(v.current.map(a => a.title)).toEqual(['new', 'old'])
  expect(v.past.map(s => s.id)).toEqual(['p11', 'p10', 'p9', 'p8', 'p7', 'p6', 'p5', 'p4', 'p3', 'p2'])
})
