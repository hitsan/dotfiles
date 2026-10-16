import { atom, read, update } from 'claude-code'
import type { EngineInterface, Register } from 'claude-code'

import type { Cursor } from '../types'
import { segments } from './blocks'

const cursor = atom({ plugin: 'block-cursor', key: 'cursor' } as const, null)
// ponytail: blocks are matched by raw text, so an identical block in two replies is marked in both
const drawnAt = new Map<string, string>()

async function allBlocks($: EngineInterface) {
  const messages = await $.session.messages()
  return messages.filter(m => m.role === 'assistant').flatMap(m => segments(m.text).filter(s => s.copy !== undefined))
}

async function move($: EngineInterface, by: number) {
  const blocks = await allBlocks($)
  if (!blocks.length) return
  const current = await read($, cursor)
  const pos = Math.min(Math.max((current?.pos ?? blocks.length + 1) + by, 1), blocks.length)
  const b = blocks[pos - 1]!
  const next: Cursor = { pos, total: blocks.length, raw: b.raw, copy: b.copy! }
  await update($, cursor, () => next)
  const requestId = drawnAt.get(b.raw)
  // Best effort: the main screen (non-fullscreen) cannot move transcript rows.
  if (requestId) await $.ui.scroll({ to: { requestId }, block: 'center' }).catch(() => undefined)
}

export const register: Register = on => {
  on('ui.render', { component: 'AssistantMessage' }, async ($, e, next) => {
    const segs = segments(e.props.text)
    for (const s of segs) if (s.copy !== undefined) drawnAt.set(s.raw, e.requestId)
    const c = await read($, cursor)
    if (!c || !segs.some(s => s.raw === c.raw)) return next(e)

    const { Box, Markdown, Text } = $.ui.resolve(e)
    return (
      <Box flexDirection="column">
        {segs.map(s => (
          <Box>
            <Text>{s.raw === c.raw ? '▶ ' : '  '}</Text>
            <Markdown text={s.raw} />
          </Box>
        ))}
      </Box>
    )
  })

  on('ui.render', { component: 'AbovePrompt' }, async ($, e, next) => {
    if (e.props.hasSurvey) return next(e)
    const { Box, Button, Text } = $.ui.resolve(e)
    const c = await read($, cursor)

    return (
      <Box>
        <Button key="prev" hotkey="k" label="前" onPress={() => move($, -1)} />
        <Button key="next" hotkey="j" label="次" onPress={() => move($, 1)} />
        <Button key="copy" hotkey="y" label="コピー" onPress={press => c && $.ui.copy({ text: c.copy, surface: press.surface })} />
        <Text dimColor>{c ? `${c.pos}/${c.total}` : ''}</Text>
      </Box>
    )
  })
}
