import { atom, read, update } from 'claude-code'
import type { EngineInterface, Register } from 'claude-code'

import type { Cursor } from '../types'
import { segments } from './blocks'

const cursor = atom({ plugin: 'block-cursor', key: 'cursor' } as const, null)
// ponytail: blocks are matched by raw text, so an identical block in two replies is marked in both
const drawnAt = new Map<string, string>()

async function move($: EngineInterface, by: number) {
  const messages = await $.session.messages()
  const replies = messages.filter(m => m.role === 'assistant')
  const blocks = replies.flatMap(m => segments(m.text).filter(s => s.copy !== undefined))
  if (!blocks.length) {
    $.ui.toast(`コピーできるブロックがありません（全 ${messages.length} 件 / 返信 ${replies.length} 件 / 文字 ${replies.reduce((n, m) => n + m.text.length, 0)}）`)
    return
  }
  const current = await read($, cursor)
  const pos = Math.min(Math.max((current?.pos ?? blocks.length + 1) + by, 1), blocks.length)
  const b = blocks[pos - 1]!
  const next: Cursor = { pos, total: blocks.length, raw: b.raw, copy: b.copy! }
  await update($, cursor, () => next)
  const requestId = drawnAt.get(b.raw)
  // Best effort: the main screen (non-fullscreen) cannot move transcript rows.
  if (requestId) await $.ui.scroll({ to: { requestId }, block: 'center' }).catch(() => undefined)
}

async function copy($: EngineInterface, c: Cursor | null, surface: Parameters<EngineInterface['ui']['copy']>[0]['surface']) {
  if (!c) return $.ui.toast('先に k でブロックを選んでください')
  const r = await $.ui.copy({ text: c.copy, surface })
  $.ui.toast(r.isCopied ? 'コピーしました' : `コピー失敗: ${r.reason}`)
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
        <Button plain key="prev" hotkey="k" label="前" onPress={() => move($, -1)} />
        <Button plain key="next" hotkey="j" label="次" onPress={() => move($, 1)} />
        <Button plain key="copy" hotkey="y" label="コピー" onPress={press => copy($, c, press.surface)} />
        <Text dimColor>{c ? `${c.pos}/${c.total}` : ''}</Text>
      </Box>
    )
  })
}
