import { expect, test } from 'claude-code/testing'

const BAND = { hasSurvey: false, isWorking: false, maxRows: 5, bodyColumns: 80, scroll: { top: 0, bodyRows: 5, rows: 1 }, view: {} } as never
const REPLY = 'see\n```\nls\n```\nand\n> quoted'
const ENGINE = { type: 'Text', props: {}, children: ['engine'] } as never

test('k picks the newest block, then older; y copies it', async ($, on) => {
  on('session.messages', async () => ({ value: [{ role: 'assistant', text: REPLY, toolUses: [] }] }) as never)
  on('ui.render', async () => ENGINE)
  const copied: string[] = []
  on('ui.copy', async (_$, e) => (copied.push(e.text), { value: { isCopied: true } }) as never)
  const band = await $.ui.mount({ plugin: 'block-cursor', surface: 'terminal', component: 'AbovePrompt', props: BAND })

  await band.press({ key: 'prev' })
  expect(await band.find({ text: '2/2' })).toBeDefined()
  await band.press({ key: 'prev' })
  await band.press({ key: 'copy' })
  expect(copied).toEqual(['ls'])
  await band.press({ key: 'next' })
  await band.press({ key: 'next' })
  expect(await band.find({ text: '2/2' })).toBeDefined()
})

test('the reply holding the cursor marks that block', async ($, on) => {
  on('session.messages', async () => ({ value: [{ role: 'assistant', text: REPLY, toolUses: [] }] }) as never)
  on('ui.render', async () => ENGINE)
  const band = await $.ui.mount({ plugin: 'block-cursor', surface: 'terminal', component: 'AbovePrompt', props: BAND })
  const msg = await $.ui.mount({ plugin: 'block-cursor', surface: 'terminal', component: 'AssistantMessage', props: { text: REPLY, isFirstOfReply: true } })
  const other = await $.ui.mount({ plugin: 'block-cursor', surface: 'terminal', component: 'AssistantMessage', props: { text: 'plain', isFirstOfReply: true } })

  await band.press({ key: 'prev' })
  await band.press({ key: 'prev' })
  expect(JSON.stringify(await msg.drawn())).toContain('▶')
  expect(await other.drawn()).toMatchObject(ENGINE)
})
