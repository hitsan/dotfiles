import { atom, read, update } from 'claude-code'
import type { EngineInterface, Register } from 'claude-code'

import type { Artifact, Cursor, Db } from '../types'
import { extractUrl, move, record, repoOf, titleOf, view } from './artifacts'
import type { Key } from './artifacts'

const PANE = 'artifact-nav'
const TITLE = 'artifacts'
const KEY = 'repos'
const repos = atom({ plugin: 'artifact-nav', key: 'repos' } as const, null, { shape: 'repos-1' })
const cursor = atom({ plugin: 'artifact-nav', key: 'cursor' } as const, { col: 0, repo: 0, item: 0 } as Cursor, { shape: 'cursor-1' })

const load = async ($: EngineInterface) => ((await $.store.get(KEY)) ?? {}) as Db

async function refresh($: EngineInterface, db?: Db) {
  const v = view(db ?? (await load($)), repoOf(await $.session.repo()).key)
  await update($, repos, () => v)
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

async function press($: EngineInterface, key: Key) {
  const r = move(await read($, cursor), key, (await read($, repos)) ?? [])
  await update($, cursor, () => r.cursor)
  // ponytail: explorer.exe opens the URL in the Windows browser (this dotfiles is WSL only); add xdg-open for other hosts.
  if (r.open) await $.process.run(['explorer.exe', r.open], { timeoutMs: 5000 }).catch(() => $.ui.toast(`開けませんでした: ${r.open}`))
}

const fmt = (t: number) => {
  const d = new Date(t)
  const p = (n: number) => String(n).padStart(2, '0')
  return `${d.getMonth() + 1}/${p(d.getDate())} ${p(d.getHours())}:${p(d.getMinutes())}`
}

export const register: Register = on => {
  on('session.start', async ($, e, next) => {
    const ran = await next(e)
    await $.command.register({ name: 'artifact-nav', description: 'リポジトリごとの artifact 一覧パネルを開閉する' })
    await refresh($)
    return ran
  })

  on('tool.call', async ($, e, next) => {
    const ran = await next(e)
    if (e.agentId || 'deny' in ran || ran.isError) return ran
    const title = await describe($, e as Record<string, any>)
    const url = title === undefined ? undefined : extractUrl(ran)
    if (!url) return ran
    const a: Artifact = { url, title: title || url, at: Date.now() }
    const db = record(await load($), repoOf(await $.session.repo()), a)
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
    const r = await $.ui.open({ id: PANE, title: TITLE, focus: true })
    return { text: r.isPlaced ? 'artifact パネルを開きました。' : `artifact パネルを表示できません: ${r.reason}` }
  })

  on('ui.render', { component: 'Pane', requestId: PANE }, async ($, e) => {
    const { Box, Button, Link, Text } = $.ui.resolve(e)
    const list = (await read($, repos)) ?? []
    if (!list.length) return <Text dimColor>まだ artifact の記録はありません。publish すると、ここにリポジトリごとに並びます。</Text>

    const c = await read($, cursor)
    const ri = Math.min(c.repo, list.length - 1)
    const items = list[ri]!.artifacts
    const ii = Math.min(c.item, items.length - 1)
    const left = Math.min(32, Math.floor((e.props.bodyColumns ?? 80) * 0.4))
    const frame = (active: boolean) => ({ borderStyle: 'round', borderColor: active ? 'cyan' : 'gray', paddingX: 1, flexDirection: 'column' }) as const
    return (
      <Box flexDirection="column">
        <Box>
          <Box {...frame(c.col === 0)} width={left}>
            <Text bold>リポジトリ</Text>
            {list.map((r, i) => (
              <Text bold={i === ri} color={i === ri ? 'cyan' : undefined}>
                {i === ri ? '▶' : ' '} {r.name} ({r.artifacts.length})
              </Text>
            ))}
          </Box>
          <Box {...frame(c.col === 1)} flexGrow={1}>
            <Text bold>artifacts</Text>
            {items.map((a, i) => (
              <Box gap={1}>
                <Text color={c.col === 1 && i === ii ? 'cyan' : undefined}>{c.col === 1 && i === ii ? '▶' : ' '}</Text>
                <Link href={a.url}>{a.title}</Link>
                <Text dimColor>{fmt(a.at)}</Text>
              </Box>
            ))}
          </Box>
        </Box>
        <Box gap={2} paddingX={1}>
          <Button plain key="down" hotkey="j" label="↓" onPress={() => press($, 'j')} />
          <Button plain key="up" hotkey="k" label="↑" onPress={() => press($, 'k')} />
          <Button plain key="left" hotkey="h" label="← 戻る" onPress={() => press($, 'h')} />
          <Button plain key="right" hotkey="l" label="→ 開く" onPress={() => press($, 'l')} />
        </Box>
      </Box>
    )
  })
}
