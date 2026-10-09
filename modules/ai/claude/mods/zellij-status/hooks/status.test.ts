import { expect, test } from 'claude-code/testing'

import { IDLE, step } from './status'
import type { Signal, Status } from './status'

const run = (signals: Signal[], from: Status = IDLE) => {
  const sent: string[] = []
  let s = from
  for (const sig of signals) {
    const r = step(s, sig)
    s = r.status
    if (r.send) sent.push(r.send)
  }
  return { s, sent }
}

test('a turn shows busy, then done when it answers', () => {
  expect(run([{ kind: 'turnStart' }, { kind: 'turnEnd', reason: 'answer' }]).sent).toEqual([
    '⏳',
    '✅',
  ])
})

test('a permission prompt shows needs-user until the tool finishes', () => {
  expect(run([{ kind: 'turnStart' }, { kind: 'needsUser' }, { kind: 'toolDone' }]).sent).toEqual([
    '⏳',
    '🔔',
    '⏳',
  ])
})

test('an interrupted turn shows done, an errored one failed', () => {
  expect(run([{ kind: 'turnStart' }, { kind: 'turnEnd', reason: 'aborted' }]).s.icon).toBe('done')
  expect(run([{ kind: 'turnStart' }, { kind: 'turnEnd', reason: 'error' }]).s.icon).toBe('failed')
})

test('a subagent finishing does not end the main turn', () => {
  const r = run([{ kind: 'turnStart' }, { kind: 'turnEnd', reason: 'answer', agentId: 'a1' }])
  expect(r.s.icon).toBe('busy')
})

test('a tool finishing after the turn ended leaves done alone', () => {
  const r = run([{ kind: 'turnStart' }, { kind: 'turnEnd', reason: 'answer' }, { kind: 'toolDone' }, { kind: 'toolDone', agentId: 'a1' }])
  expect(r.sent).toEqual(['⏳', '✅'])
})

test('a subagent asking after the main turn ended shows needs-user until its tool finishes', () => {
  const r = run([
    { kind: 'turnStart' },
    { kind: 'turnEnd', reason: 'answer' },
    { kind: 'needsUser', agentId: 'a1' },
    { kind: 'toolDone', agentId: 'a1' },
  ])
  expect(r.sent).toEqual(['⏳', '✅', '🔔', '✅'])
})

test('a subagent tool finishing does not clear the main prompt', () => {
  const r = run([{ kind: 'turnStart' }, { kind: 'needsUser' }, { kind: 'toolDone', agentId: 'a1' }])
  expect(r.s.icon).toBe('needsUser')
})

test('needs-user stays while any loop still waits', () => {
  const r = run([
    { kind: 'turnStart' },
    { kind: 'needsUser' },
    { kind: 'needsUser', agentId: 'a1' },
    { kind: 'toolDone' },
  ])
  expect(r.s.icon).toBe('needsUser')
})

test('interrupting the turn at a prompt shows done', () => {
  const r = run([{ kind: 'turnStart' }, { kind: 'needsUser' }, { kind: 'turnEnd', reason: 'aborted' }])
  expect(r.s.icon).toBe('done')
})

test('a repeated icon is not sent again', () => {
  expect(run([{ kind: 'turnStart' }, { kind: 'toolDone' }, { kind: 'toolDone' }]).sent).toEqual([
    '⏳',
  ])
})
