import type { Artifact, ArtifactView, Db } from '../types'

const URL_RE = /https:\/\/claude\.ai\/(?:code\/)?artifact\/[A-Za-z0-9_-]+/

export function extractUrl(result: unknown): string | undefined {
  return JSON.stringify(result ?? null).match(URL_RE)?.[0]
}

export function titleOf(html: string, path: string): string {
  return html.match(/<title>([^<]*)<\/title>/i)?.[1]?.trim() || path.split('/').pop() || path
}

export function record(db: Db, id: string, meta: { label: string; cwd: string }, a: Artifact): Db {
  const s = db[id] ?? { ...meta, at: a.at, artifacts: [] }
  const artifacts = s.artifacts.some(x => x.url === a.url) ? s.artifacts.map(x => (x.url === a.url ? a : x)) : [...s.artifacts, a]
  return { ...db, [id]: { ...s, at: a.at, artifacts } }
}

export function view(db: Db, current: string): ArtifactView {
  return {
    current: [...(db[current]?.artifacts ?? [])].sort((a, b) => b.at - a.at),
    past: Object.entries(db)
      .filter(([id, s]) => id !== current && s.artifacts.length)
      .map(([id, s]) => ({ id, ...s }))
      .sort((a, b) => b.at - a.at)
      .slice(0, 10),
  }
}
