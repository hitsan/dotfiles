import { expect, test } from 'claude-code/testing'

import { checklist, navigate } from './stage'

const SPEC = '# SPEC\n\n## 目的\nCSV を集計する\n\n## やらないこと\n- GUI\n\n## 完了条件\n- `cli x` が通る\n'
const BACKLOG = (todo: number, done: number, blocked: number, q = '') =>
  [
    '# BACKLOG', '', '## todo', ...Array.from({ length: todo }, (_, i) => `- [ ] T${i}: a — test: t — after: -`),
    '', '## done', ...Array.from({ length: done }, (_, i) => `- [x] D${i}: a — test: t — after: -`),
    '', '## blocked', ...Array.from({ length: blocked }, (_, i) => `- [ ] B${i}: a — fail: x`),
    '', '## 質問', q,
  ].join('\n')
const SETTINGS = '{"autoContinueAtUsageLimit": true}'

test('SPEC.md が無ければ SPEC 段階', () => {
  expect(navigate({}).stage).toBe('spec')
})

test('SPEC.md が雛形のままなら SPEC 段階', () => {
  expect(navigate({ spec: '# SPEC\n\n## 目的\n<何を作るか>\n' }).stage).toBe('spec')
})

test('SPEC.md だけあれば BACKLOG 段階', () => {
  expect(navigate({ spec: SPEC }).stage).toBe('backlog')
})

test('質問が残っていれば BACKLOG 段階', () => {
  expect(navigate({ spec: SPEC, backlog: BACKLOG(2, 0, 0, '- 通貨は円か'), settings: SETTINGS }).stage).toBe('backlog')
})

test('設定が無ければ設定段階', () => {
  expect(navigate({ spec: SPEC, backlog: BACKLOG(2, 0, 0) }).stage).toBe('settings')
})

test('todo があればループ段階で件数を持つ', () => {
  const n = navigate({ spec: SPEC, backlog: BACKLOG(3, 1, 0), settings: SETTINGS })
  expect(n.stage).toBe('loop')
  expect(n.counts).toEqual({ todo: 3, done: 1, blocked: 0 })
})

test('blocked があれば立て直し段階', () => {
  expect(navigate({ spec: SPEC, backlog: BACKLOG(1, 1, 2), settings: SETTINGS }).stage).toBe('rebuild')
})

test('todo も blocked も無ければ完了', () => {
  expect(navigate({ spec: SPEC, backlog: BACKLOG(0, 3, 0), settings: SETTINGS }).stage).toBe('done')
})

test('何も無ければ全項目が未完了で、1 番目が現在地', () => {
  const list = checklist({})
  expect(list.map(i => i.done)).toEqual([false, false, false, false, false, false])
})

test('ループ段階では 1〜4 が完了', () => {
  const list = checklist({ spec: SPEC, backlog: BACKLOG(3, 1, 0), settings: SETTINGS })
  expect(list.map(i => i.done)).toEqual([true, true, true, true, false, false])
})

test('全部 done なら全項目が完了', () => {
  const list = checklist({ spec: SPEC, backlog: BACKLOG(0, 3, 0), settings: SETTINGS })
  expect(list.every(i => i.done)).toBe(true)
})

test('blocked があればループは完了扱いにしない', () => {
  const list = checklist({ spec: SPEC, backlog: BACKLOG(0, 1, 2), settings: SETTINGS })
  expect(list.map(i => i.done)).toEqual([true, true, true, true, false, false])
})
