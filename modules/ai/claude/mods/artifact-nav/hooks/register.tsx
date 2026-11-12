import { atom, read, update } from 'claude-code'
import type { EngineInterface, Register } from 'claude-code'

import type { Artifact, Db } from '../types'
import { extractUrl, record, titleOf, view } from './artifacts'

const PANE = 'artifact-nav'
const TITLE = 'artifacts'
const KEY = 'db'
const state = atom({ plugin: 'artifact-nav', key: 'view' } as const, null, { shape: 'view-1' })
// The first prompt names the session in the list; lost on a reload, then the date and folder name it.
let label = ''

const load = async ($: EngineInterface) => ((await $.store.get(KEY)) ?? {}) as Db

async function refresh($: EngineInterface, db?: Db) {
  const v = view(db ?? (await load($)), await $.session.id())
  await update($, state, () => v)
}

// Artifact publishes a page; the Claude Docs connector creates a doc. Reads, lists and asset uploads are skipped.
async function describe($: EngineInterface, e: Record<string, any>): Promise<string | undefined> {
  if (e.tool === 'Artifact') {
    if ((e.action ?? 'publish') !== 'publish' || e.asset) return
    if (e.title) return e.title
    if (e.file_path) return titleOf(await $.fs.read(e.file_path).catch(() => ''), e.file_path)
    return ''
  }
  if (/Claude_Docs__batch$/.test(e.tool) && e.container?.create) return e.container.create.name ?? ''
}

const fmt = (t: number) => {
  const d = new Date(t)
  const p = (n: number) => String(n).padStart(2, '0')
  return `${d.getMonth() + 1}/${p(d.getDate())} ${p(d.getHours())}:${p(d.getMinutes())}`
}

export const register: Register = on => {
  on('session.start', async ($, e, next) => {
    const ran = await next(e)
    await $.command.register({ name: 'artifact-nav', description: 'セッションごとの artifact 一覧パネルを開閉する' })
    await refresh($)
    return ran
  })

  on('prompt.submit', async ($, e, next) => {
    if (!label && !e.text.startsWith('/')) label = e.text.replace(/\s+/g, ' ').slice(0, 40)
    return next(e)
  })

  on('tool.call', async ($, e, next) => {
    const ran = await next(e)
    if (e.agentId || 'deny' in ran || ran.isError) return ran
    const title = await describe($, e as Record<string, any>)
    const url = title === undefined ? undefined : extractUrl(ran)
    if (!url) return ran
    const cwd = await $.session.cwd()
    const a: Artifact = { url, title: title || url, at: Date.now() }
    const db = record(await load($), await $.session.id(), { label: label || fmt(a.at), cwd }, a)
    await $.store.set(KEY, db)
    await refresh($, db)
    return ran
  })

  on('command.run', { command: 'artifact-nav' }, async $ => {
    if ((await $.ui.panes()).some(p => p.id === PANE)) {
      await $.ui.close({ id: PANE })
      return { text: 'artifact パネルを閉じました。' }
    }
    await refresh($)
    const r = await $.ui.open({ id: PANE, title: TITLE })
    return { text: r.isPlaced ? 'artifact パネルを開きました。' : `artifact パネルを表示できません: ${r.reason}` }
  })

  on('ui.render', { component: 'Pane', requestId: PANE }, async ($, e) => {
    const { Box, Link, Text } = $.ui.resolve(e)
    const v = await read($, state)
    if (!v) return <Text dimColor>読み込み中…</Text>

    const list = (items: Artifact[]) =>
      items.map(a => (
        <Box gap={1}>
          <Text dimColor>{fmt(a.at)}</Text>
          <Link href={a.url}>{a.title}</Link>
        </Box>
      ))
    return (
      <Box flexDirection="column" gap={1}>
        <Box flexDirection="column" borderStyle="round" borderColor="cyan" paddingX={1}>
          <Text bold color="cyan">このセッション</Text>
          {v.current.length ? list(v.current) : <Text dimColor>まだ artifact はありません</Text>}
        </Box>
        <Box flexDirection="column" paddingX={1}>
          <Text bold>過去のセッション</Text>
          {v.past.length === 0 && <Text dimColor>記録はまだありません</Text>}
          {v.past.map(s => (
            <Box flexDirection="column">
              <Text dimColor>
                {fmt(s.at)} {s.cwd.split('/').pop()} — {s.label}
              </Text>
              {list([...s.artifacts].sort((a, b) => b.at - a.at))}
            </Box>
          ))}
        </Box>
      </Box>
    )
  })
}
