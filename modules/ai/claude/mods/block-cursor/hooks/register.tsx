import { atom, read, update } from 'claude-code'
import type { EngineInterface, Register } from 'claude-code'

import type { Cursor } from '../types'
import { segments } from './blocks'
import type { Segment } from './blocks'

const cursor = atom({ plugin: 'block-cursor', key: 'cursor' } as const, null)
// Filled while drawing, in transcript order; a hot reload empties it until replies are drawn again.
const drawn = new Map<string, Segment[]>()

function chunks() {
  return [...drawn].flatMap(([id, segs]) => segs.map((s, index) => ({ id, index, copy: s.copy })))
}

async function move($: EngineInterface, by: number) {
  const all = chunks()
  if (!all.length) {
    $.ui.toast('画面に返信がありません')
    return
  }
  const c = await read($, cursor)
  const at = all.findIndex(k => k.id === c?.id && k.index === c?.index)
  const i = Math.min(Math.max((at < 0 ? all.length : at) + by, 0), all.length - 1)
  const k = all[i]!
  const next: Cursor = { ...k, pos: i + 1, total: all.length }
  await update($, cursor, () => next)
  // Best effort: the main screen (non-fullscreen) cannot move transcript rows.
  await $.ui.scroll({ to: { requestId: k.id }, block: 'center' }).catch(() => undefined)
}

async function copy($: EngineInterface, c: Cursor | null, surface: Parameters<EngineInterface['ui']['copy']>[0]['surface']) {
  if (!c) return $.ui.toast('先に k で塊を選んでください')
  const r = await $.ui.copy({ text: c.copy, surface })
  $.ui.toast(r.isCopied ? 'コピーしました' : `コピー失敗: ${r.reason}`)
}

export const register: Register = on => {
  on('turn.complete', async ($, e, next) => {
    const all = chunks()
    const last = all.at(-1)
    if (last) await update($, cursor, (): Cursor => ({ ...last, pos: all.length, total: all.length }))
    return next(e)
  })

  on('ui.render', { component: 'AssistantMessage' }, async ($, e, next) => {
    const segs = segments(e.props.text)
    drawn.set(e.requestId, segs)
    const c = await read($, cursor)
    if (c?.id !== e.requestId) return next(e)

    const { Box, Markdown, Text } = $.ui.resolve(e)
    return (
      <Box flexDirection="column">
        {segs.map((s, i) => (
          <Box>
            <Text>{i === c.index ? '▶ ' : '  '}</Text>
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

    // The band's focus is not exposed, so the engine's focus ring (autoFocus) shows it instead of a border color.
    return (
      <Box borderStyle="round" borderDimColor paddingX={1} justifyContent="space-between" width={e.props.bodyColumns}>
        <Box gap={2}>
          <Button plain autoFocus key="up" hotkey="k" label="↑" onPress={() => move($, -1)} />
          <Button plain key="down" hotkey="j" label="↓" onPress={() => move($, 1)} />
          <Button plain key="copy" hotkey="y" label="⧉" onPress={press => copy($, c, press.surface)} />
        </Box>
        <Box gap={2}>
          <Text dimColor>{c ? `${c.pos}/${c.total}` : '-'}</Text>
          <Text dimColor>alt+c</Text>
        </Box>
      </Box>
    )
  })
}
