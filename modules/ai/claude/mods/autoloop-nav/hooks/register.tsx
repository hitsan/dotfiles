import { atom, read, update } from 'claude-code'
import type { EngineInterface, Register } from 'claude-code'

import { checklist, navigate } from './stage'
import type { Stage, View } from '../types'

const PANE = 'autoloop-nav'
const TITLE = 'autoloop'
const nav = atom({ plugin: 'autoloop-nav', key: 'nav' } as const, null, { shape: 'nav-2' })

const PHASES = [
  { title: '準備', how: '/poc', items: [0, 1, 2, 3] },
  { title: '実行', how: '新しいセッションで /goal', items: [4] },
  { title: 'レビュー', how: '/review', items: [5] },
  { title: '振り返り', how: '/retro', items: [6] },
]

const NEXT: Record<Stage, string> = {
  spec: '/poc を呼ぶ。要求を聞き、デモで確かめてから SPEC.md を一緒に書きます',
  backlog: '/poc を呼ぶ。BACKLOG.md の下書きと質問の続きをします',
  settings: '/poc を呼ぶ。テスト・設定・コミットを仕上げます',
  loop: '新しいセッションで /goal BACKLOG.md の todo が空になるまで /build-next を繰り返す。3 時間たったら止める',
  review: '/review を呼ぶ。デモのシナリオを実装で動かし、SPEC の完了条件を満たすか確かめます',
  rebuild: '/retro を呼ぶ。結果の要約と blocked の原因の切り分け・直しを手伝います',
  done: '/retro を呼ぶ。結果を振り返ります。追加があれば /poc で要求から伝える',
}

const readOr = async ($: EngineInterface, path: string) => {
  try {
    return await $.fs.read(path)
  } catch {
    return undefined
  }
}

async function refresh($: EngineInterface): Promise<View> {
  const [spec, backlog, settings, review] = await Promise.all(
    ['SPEC.md', 'BACKLOG.md', '.claude/settings.json', 'REVIEW.md'].map(p => readOr($, p)),
  )
  const files = { spec, backlog, settings, review }
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
      return {}
    }
    await refresh($)
    const r = await $.ui.open({ id: PANE, title: TITLE })
    return r.isPlaced ? {} : { text: `autoloop パネルを表示できません: ${r.reason}` }
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
    const total = todo + done + blocked
    const filled = total ? Math.round((done / total) * 8) : 0
    return (
      <Box flexDirection="column" gap={1}>
        {PHASES.map(ph => (
          <Box flexDirection="column">
            <Box gap={1}>
              <Text bold>{ph.title}</Text>
              <Text dimColor>{ph.how}</Text>
            </Box>
            {ph.items.map(i => {
              const it = n.items[i]!
              const here = i === cur
              return (
                <Text bold={here} color={here ? 'cyan' : it.done ? 'green' : undefined} dimColor={it.done}>
                  {here ? '▶' : ' '} {it.done ? '☑' : '☐'} {i + 1}. {it.label}{here ? '  ← 今ここ' : ''}
                </Text>
              )
            })}
          </Box>
        ))}
        {n.hasFiles && (
          <Text>
            タスク {'■'.repeat(filled) + '□'.repeat(8 - filled)} {done}/{total} done · blocked {blocked}
            {n.questions > 0 ? ` · 質問 ${n.questions}` : ''}
          </Text>
        )}
        <Box flexDirection="column" borderStyle="round" borderColor="cyan" paddingX={1}>
          <Text bold color="cyan">次にやること</Text>
          <Text>{NEXT[n.stage]}</Text>
        </Box>
      </Box>
    )
  })
}
