import { atom, read, update } from 'claude-code'
import type { EngineInterface, Register, Timer } from 'claude-code'

import type { Cursor } from '../types'
import { segments } from './blocks'
import type { Segment } from './blocks'

const cursor = atom({ plugin: 'block-cursor', key: 'cursor' } as const, null)
const isFocused = atom({ plugin: 'block-cursor', key: 'isFocused' } as const, false)
// True from closing the box until the band has let the keys go: a band with no Button hands them back.
const isClosing = atom({ plugin: 'block-cursor', key: 'isClosing' } as const, false)
let watch: Timer | undefined
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
  await update($, cursor, (): Cursor => k)
  // Best effort: the main screen (non-fullscreen) cannot move transcript rows.
  // ponytail: a reply taller than the screen only scrolls to its top, so a chunk near its end stays hidden behind the
  // prompt. The transcript has no row or key target (a Box key is refused); switch when the engine adds one.
  await $.ui.scroll({ to: { requestId: k.id }, block: 'center' }).catch(() => undefined)
}

// The engine raises nothing when Esc gives the band's keys back, but $.ui.focus is denied from then on.
// ponytail: polls every 300ms while the box is open; switch to an event if the engine adds one.
function watchFocus($: EngineInterface, band: string) {
  watch ??= $.clock.every(300, async () => {
    if (!(await $.ui.focus({ requestId: band, key: 'close' })).deny) return
    watch?.cancel()
    watch = undefined
    await update($, isFocused, () => false)
    await update($, isClosing, () => false)
  })
}

async function close($: EngineInterface) {
  await update($, isClosing, () => true)
  await update($, isFocused, () => false)
}

async function copy($: EngineInterface, c: Cursor | null, surface: Parameters<EngineInterface['ui']['copy']>[0]['surface']) {
  if (!c) return $.ui.toast('先に k で塊を選んでください')
  const r = await $.ui.copy({ text: c.copy, surface })
  $.ui.toast(r.isCopied ? 'コピーしました' : `コピー失敗: ${r.reason}`)
}

export const register: Register = on => {
  on('ui.focus', async ($, e, next) => {
    if (e.component === 'Pane') return next(e)
    // k, j and y answer their hotkeys; the ring stays on the close mark.
    if (e.element === 'up' || e.element === 'down' || e.element === 'copy') return {}
    await update($, isFocused, () => true)
    watchFocus($, e.requestId)
    return next(e)
  })

  on('turn.complete', async ($, e, next) => {
    const all = chunks()
    const last = all.at(-1)
    if (last) await update($, cursor, (): Cursor => last)
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
    const focused = await read($, isFocused)

    // autoFocus makes the band raise ui.focus when it takes the keys, which is how isFocused learns of it.
    if (!focused) {
      return (
        <Box justifyContent="flex-end" width={e.props.bodyColumns}>
          {(await read($, isClosing)) ? (
            <Text dimColor>alt+c</Text>
          ) : (
            <Button plain autoFocus key="open" label="alt+c" dimColor onPress={() => update($, isFocused, () => true)} />
          )}
        </Box>
      )
    }
    return (
      <Box paddingX={1} gap={2} width={e.props.bodyColumns}>
        <Button plain autoFocus key="close" label="●" onPress={() => close($)} />
        <Button plain key="up" hotkey="k" label="↑" onPress={() => move($, -1)} />
        <Button plain key="down" hotkey="j" label="↓" onPress={() => move($, 1)} />
        <Button plain key="copy" hotkey="y" label="⧉" onPress={press => copy($, c, press.surface)} />
      </Box>
    )
  })
}
