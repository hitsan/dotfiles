export type Artifact = { url: string; title: string; at: number }
export type RepoLog = { name: string; artifacts: Artifact[] }
export type Db = Record<string, RepoLog>
export type RepoView = { key: string; name: string; at: number; artifacts: Artifact[] }
export type Cursor = { col: 0 | 1; repo: number; item: number }

declare module 'claude-code' {
  interface PluginState {
    'artifact-nav': { repos: Shaped<RepoView[] | null>; cursor: Shaped<Cursor> }
  }
}
