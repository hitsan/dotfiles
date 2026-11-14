import type { Item, Nav, Stage } from '../types'

export type Files = { spec?: string; backlog?: string; settings?: string; review?: string }

const section = (md: string, name: string) => {
  const m = md.split(/^## /m).find(s => s.startsWith(name))
  return m ? m.split('\n').slice(1) : []
}
const items = (md: string, name: string) => section(md, name).filter(l => /^\s*- /.test(l) && l.trim() !== '-').length

// 雛形の `<...>` が残っている、または完了条件が空なら未完成とみなす
const specReady = (spec: string) => !/<[^>\n]+>/.test(spec.replace(/`[^`]*`/g, '')) && items(spec, '完了条件') > 0

export function navigate(f: Files): Nav {
  const counts = f.backlog
    ? { todo: items(f.backlog, 'todo'), done: items(f.backlog, 'done'), blocked: items(f.backlog, 'blocked') }
    : { todo: 0, done: 0, blocked: 0 }
  const questions = f.backlog ? items(f.backlog, '質問') : 0
  const nav = (stage: Stage): Nav => ({ stage, counts, questions })

  if (!f.spec || !specReady(f.spec)) return nav('spec')
  if (!f.backlog || questions > 0) return nav('backlog')
  if (!f.settings || !/"autoContinueAtUsageLimit"\s*:\s*true/.test(f.settings)) return nav('settings')
  if (counts.blocked > 0) return nav(f.review ? 'rebuild' : 'review')
  if (counts.todo > 0) return nav('loop')
  return nav(f.review ? 'done' : 'review')
}

export function checklist(f: Files): Item[] {
  const { stage, counts } = navigate(f)
  const past = (...s: Stage[]) => !s.includes(stage)
  const fin = stage === 'done'
  const ready = past('spec', 'backlog', 'settings')
  return [
    { label: 'SPEC.md を書く（要求 → デモ → 要件）', how: '/poc', done: past('spec') },
    { label: 'BACKLOG.md を作る', how: '/poc', done: past('spec') && !!f.backlog },
    { label: '質問に答え、テストを用意する', how: '/poc', done: past('spec', 'backlog') },
    { label: 'ループ用の設定を入れてコミット', how: '/poc', done: past('spec', 'backlog', 'settings') },
    { label: 'ループを回して todo を空にする', how: '新しいセッションで /goal', done: ready && counts.todo === 0 && counts.blocked === 0 },
    { label: 'できあがりをデモ・SPEC と見比べる', how: '/review', done: ready && !!f.review },
    { label: '結果を振り返り、blocked を立て直す', how: '/retro', done: fin },
  ]
}
