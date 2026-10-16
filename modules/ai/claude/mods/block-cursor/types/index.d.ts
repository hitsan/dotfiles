export type Cursor = { id: string; index: number; copy: string }

declare module 'claude-code' {
  interface PluginState {
    'block-cursor': { cursor: Cursor | null; isFocused: boolean }
  }
}
