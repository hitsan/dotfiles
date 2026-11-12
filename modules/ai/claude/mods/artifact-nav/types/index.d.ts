export type Artifact = { url: string; title: string; at: number }
export type SessionLog = { label: string; cwd: string; at: number; artifacts: Artifact[] }
export type Db = Record<string, SessionLog>
export type ArtifactView = { current: Artifact[]; past: (SessionLog & { id: string })[] }

declare module 'claude-code' {
  interface PluginState {
    'artifact-nav': { view: Shaped<ArtifactView | null> }
  }
}
