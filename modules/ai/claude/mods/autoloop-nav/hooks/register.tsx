import { atom, read, update } from 'claude-code'
import type { EngineInterface, Register } from 'claude-code'

import { navigate } from './stage'
import type { Nav, Stage } from '../types'

const PANE = 'autoloop-nav'
const TITLE = 'autoloop'
const nav = atom({ plugin: 'autoloop-nav', key: 'nav' } as const, null, { shape: 'nav-1' })

const STEPS: { label: string; how: string; at: Stage[] }[] = [
  { label: 'SPEC.md を一緒に書く', how: '/plan-backlog', at: ['spec'] },
  { label: 'BACKLOG.md を作り、質問に答える', how: '/plan-backlog', at: ['backlog'] },
  { label: 'テスト・設定・コミット', how: '/plan-backlog', at: ['settings'] },
  { label: 'ループを回す', how: '新しいセッションで /goal', at: ['loop'] },
  { label: '結果確認・blocked の立て直し', how: '/plan-backlog', at: ['rebuild', 'done'] },
]

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

async function refresh($: EngineInterface): Promise<Nav | null> {
  const [spec, backlog, settings] = await Promise.all(
    ['SPEC.md', 'BACKLOG.md', '.claude/settings.json'].map(p => readOr($, p)),
  )
  const next = spec || backlog ? navigate({ spec, backlog, settings }) : null
  await update($, nav, () => next)
  return next
}

export const register: Register = on => {
  on('session.start', async ($, e, next) => {
    const ran = await next(e)
    await $.command.register({ name: 'autoloop', description: 'autoloop の流れと今の段階をパネルに表示する' })
    if (await refresh($)) void $.ui.open({ id: PANE, title: TITLE })
    return ran
  })

  on('command.run', { command: 'autoloop' }, async $ => {
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
    if (!n) return <Text dimColor>SPEC.md も BACKLOG.md もありません。/plan-backlog で始められます。</Text>

    const cur = STEPS.findIndex(s => s.at.includes(n.stage))
    const { todo, done, blocked } = n.counts
    return (
      <Box flexDirection="column">
        {STEPS.map((s, i) => {
          const mark = i < cur || n.stage === 'done' ? '✓' : i === cur ? '▶' : ' '
          return (
            <Text bold={i === cur} dimColor={i !== cur}>
              {mark} {i + 1}. {s.label} — {s.how}
            </Text>
          )
        })}
        <Text> </Text>
        <Text>
          todo {todo} · done {done} · blocked {blocked}
          {n.questions > 0 ? ` · 質問 ${n.questions}` : ''}
        </Text>
        <Text color="cyan">次: {NEXT[n.stage]}</Text>
      </Box>
    )
  })
}
