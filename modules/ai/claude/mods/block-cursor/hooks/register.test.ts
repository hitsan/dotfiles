import { expect, test } from 'claude-code/testing'
import type { TestBody } from 'claude-code/testing'

const BAND = { hasSurvey: false, isWorking: false, maxRows: 5, bodyColumns: 80, scroll: { top: 0, bodyRows: 5, rows: 1 }, view: {} } as never
const ENGINE = { type: 'Text', props: {}, children: ['engine'] } as never

async function openBand(...[$, on]: Parameters<TestBody>) {
  on('ui.focus', async () => ({}))
  const band = await $.ui.mount({ plugin: 'block-cursor', surface: 'terminal', component: 'AbovePrompt', requestId: 'band', props: BAND } as never)
  await $.ui.focus({ requestId: 'band', key: 'open' } as never)
  return band
}

test('k walks up the chunks drawn on screen, j back down; y copies', async ($, on) => {
  on('ui.render', async () => ENGINE)
  const copied: string[] = []
  on('ui.copy', async (_$, e) => (copied.push(e.text), { value: { isCopied: true } }) as never)
  const band = await openBand($, on)
  const first = await $.ui.mount({ plugin: 'block-cursor', surface: 'terminal', component: 'AssistantMessage', props: { text: 'a\n\nb', isFirstOfReply: true } })
  const second = await $.ui.mount({ plugin: 'block-cursor', surface: 'terminal', component: 'AssistantMessage', props: { text: '```\nls\n```', isFirstOfReply: true } })

  await band.press({ key: 'up' })
  expect(JSON.stringify(await second.drawn())).toContain('▶')
  expect(await first.drawn()).toMatchObject(ENGINE)

  await band.press({ key: 'up' })
  await band.press({ key: 'copy' })
  expect(copied).toEqual(['b'])
  expect(JSON.stringify(await first.drawn())).toContain('▶')
  expect(await second.drawn()).toMatchObject(ENGINE)

  await band.press({ key: 'down' })
  await band.press({ key: 'down' })
  expect(JSON.stringify(await second.drawn())).toContain('▶')
})

test('a finished turn puts the cursor on the last chunk', async ($, on) => {
  on('ui.render', async () => ENGINE)
  on('turn.complete', async () => ({ text: 'ok' }))
  const band = await openBand($, on)
  await $.ui.mount({ plugin: 'block-cursor', surface: 'terminal', component: 'AssistantMessage', props: { text: 'a\n\nb', isFirstOfReply: true } })
  await band.press({ key: 'up' })
  await band.press({ key: 'up' })
  const reply = await $.ui.mount({ plugin: 'block-cursor', surface: 'terminal', component: 'AssistantMessage', props: { text: 'c\n\nd', isFirstOfReply: true } })

  await $.turn.complete({ answer: 'c\n\nd', reason: 'answer', turnId: 't1', durationMs: 1, isAborted: false } as never)
  expect(JSON.stringify(await reply.drawn())).toContain('▶')
})

test('the band is just alt+c until it takes the keys, then a framed box', async ($, on) => {
  on('ui.render', async () => ENGINE)
  on('ui.focus', async () => ({}))
  const band = await $.ui.mount({ plugin: 'block-cursor', surface: 'terminal', component: 'AbovePrompt', requestId: 'band', props: BAND } as never)
  expect(await band.find({ key: 'open' })).toMatchObject({ props: { label: 'alt+c' } })
  expect(await band.find({ key: 'up' })).toBeUndefined()

  await $.ui.focus({ requestId: 'band', key: 'open' } as never)
  expect(await band.find({ type: 'Box' })).toMatchObject({ props: { borderStyle: 'round' } })
  expect(await band.find({ key: 'up' })).toBeDefined()
  expect(await band.find({ text: 'esc' })).toBeDefined()
})

test('the framed box holds alt+c, right-aligned, until the band takes the keys', async ($, on) => {
  on('ui.render', async () => ENGINE)
  const band = await $.ui.mount({ plugin: 'block-cursor', surface: 'terminal', component: 'AbovePrompt', requestId: 'band', props: BAND } as never)
  expect(await band.drawn()).toMatchObject({ type: 'Box', props: { borderStyle: 'round', width: 80 } })
  expect(await band.find({ key: 'open' })).toMatchObject({ props: { label: 'alt+c' } })
})
