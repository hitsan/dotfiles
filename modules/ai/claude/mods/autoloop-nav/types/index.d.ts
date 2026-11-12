export type Stage = 'spec' | 'backlog' | 'settings' | 'loop' | 'rebuild' | 'done'
export type Counts = { todo: number; done: number; blocked: number }
export type Item = { label: string; how: string; done: boolean }
export type Nav = { stage: Stage; counts: Counts; questions: number }
export type View = Nav & { items: Item[]; hasFiles: boolean }

declare module 'claude-code' {
  interface PluginState {
    'autoloop-nav': { nav: Shaped<View | null> }
  }
}
