import { expect, test } from 'claude-code/testing'

const PANE = {
  plugin: 'artifact-nav',
  component: 'Pane',
  requestId: 'artifact-nav',
  props: { title: 'artifacts', isFocused: true, bodyColumns: 80, placement: 'dock', scroll: { offset: 0, bodyRows: 20 }, view: {} },
} as const

const DB = {
  'hitsan/dotfiles': { name: 'hitsan/dotfiles', artifacts: [{ url: 'https://claude.ai/artifact/A', title: '使い方', at: 5 }] },
  'hitsan/thiking': { name: 'hitsan/thiking', artifacts: [{ url: 'https://claude.ai/artifact/B', title: '解説', at: 2 }] },
}

function engine(on: any, saved: unknown[] = [], ran: string[][] = []) {
  on('store.get', () => ({ value: DB }))
  on('store.set', (_: unknown, e: any) => (saved.push(e.value), { value: undefined }))
  on('session.repo', () => ({ value: { root: '/h/dotfiles', remote: 'git@github.com:hitsan/dotfiles.git', internal: false } }))
  on('command.register', () => ({ value: { command: 'artifact-nav' } }))
  on('process.run', (_: unknown, e: any) => (ran.push(e.argv ?? e), { value: { code: 0, stdout: '', stderr: '' } }))
  on('session.start', (_: unknown, e: any) => ({ cwd: e.cwd }))
}

test('左にリポジトリ、右にその artifact。j で次のリポジトリ、l で右へ、Enter で開く', async ($, on) => {
  const ran: string[][] = []
  engine(on, [], ran)
  await $.session.start({ cwd: '/h/dotfiles', surface: 'terminal', isInteractive: true })
  const ui = await $.ui.mount({ ...PANE, surface: 'terminal' })
  expect((await ui.find({ type: 'Text', text: /▶/ }))?.text).toContain('hitsan/dotfiles (1)')
  expect(await ui.find({ type: 'Link', text: /使い方/ })).toBeDefined()

  await ui.press({ key: 'down' })
  expect((await ui.find({ type: 'Text', text: /▶/ }))?.text).toContain('hitsan/thiking')
  expect(await ui.find({ type: 'Link', text: /解説/ })).toBeDefined()

  await ui.press({ key: 'right' })
  await ui.press({ key: 'right' })
  expect(ran).toEqual([])
  await ui.press({ key: 'enter' })
  expect(JSON.stringify(ran)).toContain('https://claude.ai/artifact/B')
  await ui.unmount()
})

test('Artifact の publish を今のリポジトリに記録する', async ($, on) => {
  const saved: any[] = []
  engine(on, saved)
  on('fs.read', () => ({ value: '<title>新しいページ</title>' }))
  on('tool.call', () => ({ result: { text: 'Published at https://claude.ai/artifact/NEW (Version 1)' } }))
  await $.session.start({ cwd: '/h/dotfiles', surface: 'terminal', isInteractive: true })
  await $.tool.call({ tool: 'Artifact', file_path: '/s/new.html' } as never)
  expect(saved.at(-1)['hitsan/dotfiles'].artifacts.map((a: any) => a.title)).toEqual(['使い方', '新しいページ'])
})

test('q で閉じる（/artifact-nav を通すので、Alt+c の帯が開いたパネルも閉じられる）', async ($, on) => {
  const ran: string[] = []
  engine(on)
  on('command.run', (_: unknown, e: any) => (ran.push(e.command), { value: { text: '' } }))
  await $.session.start({ cwd: '/h/dotfiles', surface: 'terminal', isInteractive: true })
  const ui = await $.ui.mount({ ...PANE, surface: 'terminal' })
  expect(await ui.find({ key: 'close' })).toMatchObject({ props: { hotkey: 'q' } })
  await ui.press({ key: 'close' })
  expect(ran).toEqual(['artifact-nav'])
  await ui.unmount()
})
