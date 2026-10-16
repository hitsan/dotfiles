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
  expect(await band.find({ text: 'alt+c' })).toBeDefined()
  await band.press({ key: 'up' })
  expect(await band.find({ text: '3/3' })).toBeDefined()
  expect(JSON.stringify(await second.drawn())).toContain('▶')
  expect(await first.drawn()).toMatchObject(ENGINE)

  await band.press({ key: 'up' })
  await band.press({ key: 'copy' })
  expect(copied).toEqual(['b'])
  expect(JSON.stringify(await first.drawn())).toContain('▶')
  expect(await second.drawn()).toMatchObject(ENGINE)

  await band.press({ key: 'down' })
  await band.press({ key: 'down' })
  expect(await band.find({ text: '3/3' })).toBeDefined()
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
  expect(await band.find({ text: '4/4' })).toBeDefined()
  expect(JSON.stringify(await reply.drawn())).toContain('▶')
})
