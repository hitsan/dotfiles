import { expect, test } from 'claude-code/testing'

const PANE = {
  plugin: 'autoloop-nav',
  component: 'Pane',
  requestId: 'autoloop-nav',
  props: { title: 'autoloop', isFocused: false, bodyColumns: 80, placement: 'dock', scroll: { offset: 0, bodyRows: 20 }, view: {} },
} as const

const FILES: Record<string, string> = {
  'SPEC.md': '# SPEC\n\n## 目的\nx\n\n## 完了条件\n- `cli x` が通る\n',
  'BACKLOG.md': '# BACKLOG\n\n## todo\n- [ ] T1: a\n- [ ] T2: b\n- [ ] T3: c\n\n## done\n- [x] T0: z\n\n## blocked\n\n## 質問\n',
  '.claude/settings.json': '{"autoContinueAtUsageLimit": true}',
}

test('ループ段階では 5 番目に ▶ が付き、次の手順が出る', async ($, on) => {
  on('fs.read', (_, e) => {
    const key = Object.keys(FILES).find(k => e.path.endsWith(k))
    return key ? { value: FILES[key] } : { deny: 'ENOENT' }
  })
  on('command.register', () => ({ value: { command: 'autoloop' } }))
  on('ui.open', () => ({ value: { isPlaced: true } }))
  on('session.start', (_, e) => ({ cwd: e.cwd }))
  await $.session.start({ cwd: '/', surface: 'terminal', isInteractive: true })

  const ui = await $.ui.mount({ ...PANE, surface: 'terminal' })
  expect((await ui.find({ type: 'Text', text: /▶/ }))?.text).toContain('☐ 5. ループを回して')
  expect((await ui.find({ type: 'Text', text: /^タスク/ }))?.text).toBe('タスク ■■□□□□□□ 1/4 done · blocked 0')
  expect((await ui.find({ type: 'Text', text: /今ここ/ }))?.text).toContain('5. ループを回して')
  expect((await ui.find({ type: 'Text', text: /\/goal BACKLOG/ }))).toBeDefined()
  await ui.unmount()
})

test('何も無くても全体の流れを出し、1 番目が現在地', async ($, on) => {
  on('fs.read', () => ({ deny: 'ENOENT' }))
  on('command.register', () => ({ value: { command: 'autoloop' } }))
  on('session.start', (_, e) => ({ cwd: e.cwd }))
  await $.session.start({ cwd: '/', surface: 'terminal', isInteractive: true })

  const ui = await $.ui.mount({ ...PANE, surface: 'terminal' })
  const rows = (await ui.findAll({ type: 'Text', text: /☐/ })).map(t => t.text)
  expect(rows.length).toBe(7)
  expect(rows[0]).toContain('▶ ☐ 1. SPEC.md を書く')
  expect((await ui.find({ type: 'Text', text: /^タスク/ }))).toBeUndefined()
  expect((await ui.find({ type: 'Text', text: /準備/ }))).toBeDefined()
  await ui.unmount()
})

test('todo が空で REVIEW.md があれば、レビューまで完了して振り返りを案内する', async ($, on) => {
  const files: Record<string, string> = {
    ...FILES,
    'BACKLOG.md': '# BACKLOG\n\n## todo\n\n## done\n- [x] T0: z\n\n## blocked\n- [ ] B1: y — fail: x\n\n## 質問\n',
    'REVIEW.md': '# REVIEW\n\n- 2026-11-14 OK\n',
  }
  on('fs.read', (_, e) => {
    const key = Object.keys(files).find(k => e.path.endsWith(k))
    return key ? { value: files[key] } : { deny: 'ENOENT' }
  })
  on('command.register', () => ({ value: { command: 'autoloop' } }))
  on('ui.open', () => ({ value: { isPlaced: true } }))
  on('session.start', (_, e) => ({ cwd: e.cwd }))
  await $.session.start({ cwd: '/', surface: 'terminal', isInteractive: true })

  const ui = await $.ui.mount({ ...PANE, surface: 'terminal' })
  expect((await ui.find({ type: 'Text', text: /☑ 6\./ }))?.text).toContain('6. できあがりを')
  expect((await ui.find({ type: 'Text', text: /\/retro を呼ぶ/ }))).toBeDefined()
  await ui.unmount()
})

test('/autoloop は開いていれば閉じ、閉じていれば開く', async ($, on) => {
  const calls: string[] = []
  let open = false
  on('fs.read', () => ({ deny: 'ENOENT' }))
  on('ui.panes', () => ({ value: open ? [{ id: 'autoloop-nav', title: 'autoloop', isShown: true, isFocused: false, isPlaced: true }] : [] }))
  on('ui.open', () => { calls.push('open'); open = true; return { value: { isPlaced: true } } })
  on('ui.close', () => { calls.push('close'); open = false; return { value: undefined } })

  await $.command.run({ command: 'autoloop', args: '' })
  await $.command.run({ command: 'autoloop', args: '' })
  expect(calls).toEqual(['open', 'close'])
})
