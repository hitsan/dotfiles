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

test('ループ段階では 4 番目に ▶ が付き、次の手順が出る', async ($, on) => {
  on('fs.read', (_, e) => {
    const key = Object.keys(FILES).find(k => e.path.endsWith(k))
    return key ? { value: FILES[key] } : { deny: 'ENOENT' }
  })
  on('command.register', () => ({ value: { command: 'autoloop' } }))
  on('ui.open', () => ({ value: { isPlaced: true } }))
  on('session.start', (_, e) => ({ cwd: e.cwd }))
  await $.session.start({ cwd: '/', surface: 'terminal', isInteractive: true })

  const ui = await $.ui.mount({ ...PANE, surface: 'terminal' })
  expect((await ui.find({ type: 'Text', text: /▶/ }))?.text).toContain('4. ループを回す')
  expect((await ui.find({ type: 'Text', text: /^todo/ }))?.text).toBe('todo 3 · done 1 · blocked 0')
  expect((await ui.find({ type: 'Text', text: /^次:/ }))?.text).toContain('/goal')
  await ui.unmount()
})

test('SPEC も BACKLOG も無ければ始め方を出す', async $ => {
  const ui = await $.ui.mount({ ...PANE, surface: 'terminal' })
  expect((await ui.find({ type: 'Text' }))?.text).toContain('/plan-backlog')
  await ui.unmount()
})
