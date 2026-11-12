import type { Nav, Stage } from '../types'

export type Files = { spec?: string; backlog?: string; settings?: string }

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
  if (counts.blocked > 0) return nav('rebuild')
  if (counts.todo > 0) return nav('loop')
  return nav('done')
}
