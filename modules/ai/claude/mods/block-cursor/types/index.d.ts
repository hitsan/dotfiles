export type Cursor = { id: string; index: number; pos: number; total: number; copy: string }

declare module 'claude-code' {
  interface PluginState {
    'block-cursor': { cursor: Cursor | null }
  }
}
