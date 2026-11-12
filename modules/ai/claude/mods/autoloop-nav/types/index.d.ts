export type Stage = 'spec' | 'backlog' | 'settings' | 'loop' | 'rebuild' | 'done'
export type Counts = { todo: number; done: number; blocked: number }
export type Nav = { stage: Stage; counts: Counts; questions: number }

declare module 'claude-code' {
  interface PluginState {
    'autoloop-nav': { nav: Shaped<Nav | null> }
  }
}
