import type { EngineInterface, Register } from 'claude-code'

import { IDLE, step } from './status'
import type { Signal } from './status'

const NEEDS_USER_NOTIFICATIONS = ['permission_prompt', 'elicitation_dialog', 'agent_needs_input']

let status = IDLE
let queue: Promise<unknown> = Promise.resolve()

// Chained, not awaited: the tab script runs in event order without holding up the turn.
function run($: EngineInterface, icon: string) {
  queue = queue
    .then(() => $.process.run([`${$.plugin.root}/scripts/claude-tab-status.sh`, icon], { timeoutMs: 5000 }))
    .catch(() => undefined)
}

function signal($: EngineInterface, sig: Signal) {
  const r = step(status, sig)
  status = r.status
  if (r.send) run($, r.send)
}

export const register: Register = on => {
  on('turn.start', async ($, e, next) => {
    signal($, { kind: 'turnStart' })
    return next(e)
  })

  on('classic.PermissionRequest', async ($, e, next) => {
    signal($, { kind: 'needsUser' })
    return next(e)
  })

  on('classic.Notification', async ($, e, next) => {
    if (NEEDS_USER_NOTIFICATIONS.includes(e.notification_type ?? '')) signal($, { kind: 'needsUser' })
    return next(e)
  })

  on('tool.call', async ($, e, next) => {
    if (e.tool === 'AskUserQuestion') signal($, { kind: 'needsUser' })
    const ran = await next(e)
    signal($, { kind: 'toolDone' })
    return ran
  })

  on('turn.complete', async ($, e, next) => {
    signal($, { kind: 'turnEnd', reason: e.reason, agentId: e.agentId })
    return next(e)
  })

  on('session.end', async ($, e, next) => {
    status = IDLE
    run($, '-')
    return next(e)
  })
}
