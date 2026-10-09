import { expect, test } from 'claude-code/testing'

test('engine events reach the bundled tab script in order, as icons', async ($, on) => {
  const sent: string[] = []
  let allSent = () => {}
  const fourSent = new Promise<void>(r => (allSent = r))
  on('process.run', async (_$, e) => {
    expect(e.argv[0]).toMatch(/\/zellij-status\/scripts\/claude-tab-status\.sh$/)
    sent.push(e.argv[1]!)
    if (sent.length === 4) allSent()
    return { value: { exitCode: 0, stdout: '', stderr: '' } } as never
  })
  on('turn.start', async () => ({ turnId: 't1' }))
  on('turn.complete', async () => ({ text: 'ok' }))
  on('session.end', async () => ({ sessionId: 's1' }))
  on('classic.PermissionRequest', async () => ({}))
  await $.turn.start({ text: 'hi', turnId: 't1' } as never)
  await $.classic.PermissionRequest({ tool_name: 'Bash', tool_input: { command: 'ls' } } as never)
  await $.turn.complete({ answer: 'ok', reason: 'answer', turnId: 't1', durationMs: 1, isAborted: false } as never)
  await $.session.end({ reason: 'other' } as never)
  await fourSent
  expect(sent).toEqual(['⏳', '🔔', '✅', '-'])
})

test('a subagent tool finishing does not clear the main prompt', async ($, on) => {
  const sent: string[] = []
  let ended = () => {}
  const sessionEnded = new Promise<void>(r => (ended = r))
  on('process.run', async (_$, e) => {
    sent.push(e.argv[1]!)
    if (e.argv[1] === '-') ended()
    return { value: { exitCode: 0, stdout: '', stderr: '' } } as never
  })
  on('turn.start', async () => ({ turnId: 't1' }))
  on('session.end', async () => ({ sessionId: 's1' }))
  on('classic.PermissionRequest', async () => ({}))
  on('tool.call', async () => ({ result: 'ok' }) as never)
  await $.turn.start({ text: 'hi', turnId: 't1' } as never)
  await $.classic.PermissionRequest({ tool_name: 'Bash', tool_input: { command: 'ls' } } as never)
  await $.tool.call({ tool: 'Bash', command: 'ls', agentId: 'a1' } as never)
  await $.session.end({ reason: 'other' } as never)
  await sessionEnded
  expect(sent).toEqual(['⏳', '🔔', '-'])
})
