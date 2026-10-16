export type Cursor = { pos: number; total: number; raw: string; copy: string }

declare module 'claude-code' {
  interface PluginState {
    'block-cursor': { cursor: Cursor | null }
  }
}
