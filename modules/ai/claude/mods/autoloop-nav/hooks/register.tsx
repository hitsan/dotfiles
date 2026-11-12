import { atom, read, update } from 'claude-code'
import type { EngineInterface, Register } from 'claude-code'

import { checklist, navigate } from './stage'
import type { Stage, View } from '../types'

const PANE = 'autoloop-nav'
const TITLE = 'autoloop'
const nav = atom({ plugin: 'autoloop-nav', key: 'nav' } as const, null, { shape: 'nav-2' })

const NEXT: Record<Stage, string> = {
  spec: '/plan-backlog を呼ぶ。SPEC.md を質問しながら一緒に書きます',
  backlog: '/plan-backlog を呼ぶ。BACKLOG.md の下書きと質問の続きをします',
  settings: '/plan-backlog を呼ぶ。テスト・設定・コミットを仕上げます',
  loop: '新しいセッションで /goal BACKLOG.md の todo が空になるまで /build-next を繰り返す。3 時間たったら止める',
  rebuild: '/plan-backlog を呼ぶ。blocked の原因の切り分けと直しを手伝います',
  done: 'すべて done。git log で結果を確認する。追加があれば SPEC.md に足して /plan-backlog',
}

const readOr = async ($: EngineInterface, path: string) => {
  try {
    return await $.fs.read(path)
  } catch {
    return undefined
  }
}

async function refresh($: EngineInterface): Promise<View> {
  const [spec, backlog, settings] = await Promise.all(
    ['SPEC.md', 'BACKLOG.md', '.claude/settings.json'].map(p => readOr($, p)),
  )
  const files = { spec, backlog, settings }
  const view = { ...navigate(files), items: checklist(files), hasFiles: !!(spec || backlog) }
  await update($, nav, () => view)
  return view
}

export const register: Register = on => {
  on('session.start', async ($, e, next) => {
    const ran = await next(e)
    await $.command.register({ name: 'autoloop', description: 'autoloop の流れと今の段階を示すパネルを開閉する' })
    if ((await refresh($)).hasFiles) void $.ui.open({ id: PANE, title: TITLE })
    return ran
  })

  on('command.run', { command: 'autoloop' }, async $ => {
    if ((await $.ui.panes()).some(p => p.id === PANE)) {
      await $.ui.close({ id: PANE })
      return { text: 'autoloop パネルを閉じました。' }
    }
    await refresh($)
    await $.ui.open({ id: PANE, title: TITLE })
    return { text: 'autoloop パネルを開きました。' }
  })

  on('turn.complete', async ($, e, next) => {
    const ran = await next(e)
    if (!e.agentId) await refresh($)
    return ran
  })

  on('ui.render', { component: 'Pane', requestId: PANE }, async ($, e) => {
    const { Box, Text } = $.ui.resolve(e)
    const n = await read($, nav)
    if (!n) return <Text dimColor>読み込み中…</Text>

    const cur = n.items.findIndex(i => !i.done)
    const { todo, done, blocked } = n.counts
    return (
      <Box flexDirection="column">
        {n.items.map((it, i) => (
          <Text bold={i === cur} dimColor={it.done}>
            {i === cur ? '▶' : ' '} {it.done ? '☑' : '☐'} {i + 1}. {it.label} — {it.how}
          </Text>
        ))}
        <Text> </Text>
        {n.hasFiles && (
          <Text>
            todo {todo} · done {done} · blocked {blocked}
            {n.questions > 0 ? ` · 質問 ${n.questions}` : ''}
          </Text>
        )}
        <Text color="cyan">次: {NEXT[n.stage]}</Text>
      </Box>
    )
  })
}
