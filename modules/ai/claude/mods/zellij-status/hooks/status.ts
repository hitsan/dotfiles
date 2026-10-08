export type Icon = 'busy' | 'needsUser' | 'done' | 'failed'
export type Status = { isActive: boolean; icon: Icon | null }
export type Signal =
  | { kind: 'turnStart' }
  | { kind: 'needsUser' }
  | { kind: 'toolDone' }
  | { kind: 'turnEnd'; reason: string; agentId?: string }

export const IDLE: Status = { isActive: false, icon: null }

const GLYPH: Record<Icon, string> = {
  busy: '⏳',
  needsUser: '🔔',
  done: '✅',
  failed: '✗',
}

export const step = (s: Status, sig: Signal): { status: Status; send?: string } => {
  const to = (icon: Icon, isActive: boolean) => ({
    status: { isActive, icon },
    send: icon === s.icon ? undefined : GLYPH[icon],
  })
  if (sig.kind === 'turnStart') return to('busy', true)
  if (!s.isActive) return { status: s }
  if (sig.kind === 'needsUser') return to('needsUser', true)
  if (sig.kind === 'toolDone') return to('busy', true)
  if (sig.agentId) return { status: s }
  return to(sig.reason === 'error' ? 'failed' : 'done', false)
}
