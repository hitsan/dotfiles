export type Icon = 'busy' | 'needsUser' | 'done' | 'failed'
// waiting: loops held on the user, '' for the main loop.
export type Status = { isActive: boolean; ended: 'done' | 'failed' | null; waiting: string[]; icon: Icon | null }
export type Signal =
  | { kind: 'turnStart' }
  | { kind: 'needsUser'; agentId?: string }
  | { kind: 'toolDone'; agentId?: string }
  | { kind: 'turnEnd'; reason: string; agentId?: string }

export const IDLE: Status = { isActive: false, ended: null, waiting: [], icon: null }

const GLYPH: Record<Icon, string> = {
  busy: '⏳',
  needsUser: '🔔',
  done: '✅',
  failed: '✗',
}

const iconOf = (s: Omit<Status, 'icon'>): Icon | null =>
  s.waiting.length ? 'needsUser' : s.isActive ? 'busy' : s.ended

// ponytail: waits are keyed per loop, so a parallel tool finishing in the same loop clears its prompt early; key by tool_use_id if that shows up.
const next = (s: Status, sig: Signal): Omit<Status, 'icon'> => {
  const loop = ('agentId' in sig && sig.agentId) || ''
  const waiting = s.waiting.filter(w => w !== loop)
  switch (sig.kind) {
    case 'turnStart':
      return { ...s, isActive: true }
    case 'needsUser':
      return { ...s, waiting: [...waiting, loop] }
    case 'toolDone':
      return { ...s, waiting }
    case 'turnEnd':
      if (loop) return { ...s, waiting }
      return { ...s, waiting, isActive: false, ended: sig.reason === 'error' ? 'failed' : 'done' }
  }
}

export const step = (s: Status, sig: Signal): { status: Status; send?: string } => {
  const n = next(s, sig)
  const icon = iconOf(n)
  return { status: { ...n, icon }, send: icon && icon !== s.icon ? GLYPH[icon] : undefined }
}
