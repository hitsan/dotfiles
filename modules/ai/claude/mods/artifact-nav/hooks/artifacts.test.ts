import { expect, test } from 'claude-code/testing'

import { extractUrl, move, record, repoOf, titleOf, view } from './artifacts'

test('結果の中から artifact の URL を拾う', () => {
  expect(extractUrl({ text: 'Published x at https://claude.ai/artifact/TpEoqEJ (Version 2)' })).toBe('https://claude.ai/artifact/TpEoqEJ')
  expect(extractUrl({ frame: { url: 'https://claude.ai/code/artifact/ab-12' } })).toBe('https://claude.ai/code/artifact/ab-12')
  expect(extractUrl({ text: 'nothing' })).toBeUndefined()
})

test('タイトルは <title>、無ければファイル名', () => {
  expect(titleOf('<title>autoloop の使い方</title><style>', '/s/guide.html')).toBe('autoloop の使い方')
  expect(titleOf('<p>x</p>', '/s/guide.html')).toBe('guide.html')
})

test('リポジトリは origin の owner/name、無ければフォルダ名、git の外は other', () => {
  expect(repoOf({ root: '/h/dotfiles', remote: 'git@github.com:hitsan/dotfiles.git' })).toEqual({ key: 'hitsan/dotfiles', name: 'hitsan/dotfiles' })
  expect(repoOf({ root: '/h/x', remote: 'https://github.com/a/b.git' })).toEqual({ key: 'a/b', name: 'a/b' })
  expect(repoOf({ root: '/h/local', remote: null })).toEqual({ key: '/h/local', name: 'local' })
  expect(repoOf(null)).toEqual({ key: '', name: 'other' })
})

test('同じ URL は 1 件にまとめ、タイトルと時刻を更新する', () => {
  let db = record({}, { key: 'r', name: 'R' }, { url: 'u1', title: 'A', at: 1 })
  db = record(db, { key: 'r', name: 'R' }, { url: 'u1', title: 'A2', at: 2 })
  db = record(db, { key: 'r', name: 'R' }, { url: 'u2', title: 'B', at: 3 })
  expect(db.r!.artifacts).toEqual([{ url: 'u1', title: 'A2', at: 2 }, { url: 'u2', title: 'B', at: 3 }])
})

test('今のリポジトリが先頭、他は最後に作った順。artifact は新しい順', () => {
  let db = {}
  db = record(db, { key: 'a', name: 'A' }, { url: '1', title: 'a1', at: 1 })
  db = record(db, { key: 'b', name: 'B' }, { url: '2', title: 'b1', at: 5 })
  db = record(db, { key: 'c', name: 'C' }, { url: '3', title: 'c1', at: 3 })
  db = record(db, { key: 'c', name: 'C' }, { url: '4', title: 'c2', at: 4 })
  const v = view(db, 'c')
  expect(v.map(r => r.key)).toEqual(['c', 'b', 'a'])
  expect(v[0]!.artifacts.map(a => a.title)).toEqual(['c2', 'c1'])
})

test('j/k は列の中で動き、l と Enter で右の列へ、右の列の Enter は URL を開く、h で左へ', () => {
  const repos = view(
    record(record(record({}, { key: 'a', name: 'A' }, { url: 'u1', title: 't1', at: 1 }), { key: 'a', name: 'A' }, { url: 'u2', title: 't2', at: 2 }), { key: 'b', name: 'B' }, { url: 'u3', title: 't3', at: 0 }),
    'a',
  )
  let c = { col: 0 as const, repo: 0, item: 0 }
  expect(move(c, 'k', repos).cursor).toEqual(c)
  expect(move(c, 'j', repos).cursor).toEqual({ col: 0, repo: 1, item: 0 })
  const right = move(c, 'l', repos).cursor
  expect(right).toEqual({ col: 1, repo: 0, item: 0 })
  expect(move(right, 'j', repos).cursor).toEqual({ col: 1, repo: 0, item: 1 })
  expect(move(move(right, 'j', repos).cursor, 'enter', repos).open).toBe('u1')
  expect(move(right, 'l', repos)).toEqual({ cursor: right })
  expect(move(c, 'enter', repos).cursor).toEqual(right)
  expect(move(right, 'h', repos).cursor).toEqual({ col: 0, repo: 0, item: 0 })
})
