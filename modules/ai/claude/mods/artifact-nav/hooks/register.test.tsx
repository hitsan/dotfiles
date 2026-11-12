import { expect, test } from 'claude-code/testing'

const PANE = {
  plugin: 'artifact-nav',
  component: 'Pane',
  requestId: 'artifact-nav',
  props: { title: 'artifacts', isFocused: false, bodyColumns: 80, placement: 'dock', scroll: { offset: 0, bodyRows: 20 }, view: {} },
} as const

const DB = {
  now: { label: 'artifact のナビ', cwd: '/r/dotfiles', at: 5, artifacts: [{ url: 'https://claude.ai/artifact/A', title: '使い方', at: 5 }] },
  old: { label: '前の作業', cwd: '/r/thiking', at: 2, artifacts: [{ url: 'https://claude.ai/artifact/B', title: '解説', at: 2 }] },
}

function engine(on: Parameters<Parameters<typeof test>[1]>[1], saved: unknown[] = []) {
  on('store.get', () => ({ value: DB }))
  on('store.set', (_, e) => (saved.push(e.value), { value: undefined }))
  on('session.id', () => ({ value: 'now' }))
  on('session.cwd', () => ({ value: '/r/dotfiles' }))
  on('command.register', () => ({ value: { command: 'artifact-nav' } }))
  on('session.start', (_, e) => ({ cwd: e.cwd }))
}

test('今のセッションと過去のセッションの artifact を分けて出す', async ($, on) => {
  engine(on)
  await $.session.start({ cwd: '/r/dotfiles', surface: 'terminal', isInteractive: true })
  const ui = await $.ui.mount({ ...PANE, surface: 'terminal' })
  expect(await ui.find({ type: 'Text', text: /このセッション/ })).toBeDefined()
  expect(await ui.find({ type: 'Link', text: /使い方/ })).toBeDefined()
  expect(await ui.find({ type: 'Text', text: /thiking — 前の作業/ })).toBeDefined()
  await ui.unmount()
})

test('Artifact の publish を記録する', async ($, on) => {
  const saved: any[] = []
  engine(on, saved)
  on('fs.read', () => ({ value: '<title>新しいページ</title>' }))
  on('tool.call', () => ({ result: { text: 'Published at https://claude.ai/artifact/NEW (Version 1)' } }))
  await $.session.start({ cwd: '/r/dotfiles', surface: 'terminal', isInteractive: true })
  await $.tool.call({ tool: 'Artifact', file_path: '/s/new.html' } as never)
  expect(saved.at(-1).now.artifacts.map((a: any) => a.title)).toEqual(['使い方', '新しいページ'])
})
