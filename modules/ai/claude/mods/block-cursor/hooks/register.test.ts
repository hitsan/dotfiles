import { expect, test } from 'claude-code/testing'

const BAND = { hasSurvey: false, isWorking: false, maxRows: 5, bodyColumns: 80, scroll: { top: 0, bodyRows: 5, rows: 1 }, view: {} } as never
const ENGINE = { type: 'Text', props: {}, children: ['engine'] } as never

test('k walks up the chunks drawn on screen, j back down; y copies', async ($, on) => {
  on('ui.render', async () => ENGINE)
  const copied: string[] = []
  on('ui.copy', async (_$, e) => (copied.push(e.text), { value: { isCopied: true } }) as never)
  const band = await $.ui.mount({ plugin: 'block-cursor', surface: 'terminal', component: 'AbovePrompt', props: BAND })
  const first = await $.ui.mount({ plugin: 'block-cursor', surface: 'terminal', component: 'AssistantMessage', props: { text: 'a\n\nb', isFirstOfReply: true } })
  const second = await $.ui.mount({ plugin: 'block-cursor', surface: 'terminal', component: 'AssistantMessage', props: { text: '```\nls\n```', isFirstOfReply: true } })

  expect(await band.find({ type: 'Box' })).toMatchObject({ props: { borderStyle: 'round' } })
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
  const band = await $.ui.mount({ plugin: 'block-cursor', surface: 'terminal', component: 'AbovePrompt', props: BAND })
  await $.ui.mount({ plugin: 'block-cursor', surface: 'terminal', component: 'AssistantMessage', props: { text: 'a\n\nb', isFirstOfReply: true } })
  await band.press({ key: 'up' })
  await band.press({ key: 'up' })
  const reply = await $.ui.mount({ plugin: 'block-cursor', surface: 'terminal', component: 'AssistantMessage', props: { text: 'c\n\nd', isFirstOfReply: true } })

  await $.turn.complete({ answer: 'c\n\nd', reason: 'answer', turnId: 't1', durationMs: 1, isAborted: false } as never)
  expect(JSON.stringify(await reply.drawn())).toContain('▶')
})

test('the hint says esc while the band holds the keys, alt+c once the prompt is edited', async ($, on) => {
  on('ui.render', async () => ENGINE)
  on('ui.focus', async () => ({}))
  on('prompt.edit', async (_$, e) => ({ text: e.text, cursor: e.cursor }))
  const band = await $.ui.mount({ plugin: 'block-cursor', surface: 'terminal', component: 'AbovePrompt', requestId: 'band', props: BAND } as never)
  expect(await band.find({ text: /alt\+c/ })).toBeDefined()

  await $.ui.focus({ requestId: 'band', key: 'up' } as never)
  expect(await band.find({ text: /esc/ })).toBeDefined()
  expect(await band.find({ text: /alt\+c/ })).toBeUndefined()

  await ($.prompt as unknown as { edit: (e: unknown) => Promise<unknown> }).edit({ origin: { kind: 'person' }, text: 'h', cursor: 1, start: 0, end: 0, inputText: 'h' } as never)
  expect(await band.find({ text: /alt\+c/ })).toBeDefined()
})
