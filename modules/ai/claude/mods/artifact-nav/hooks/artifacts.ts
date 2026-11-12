import type { Artifact, Cursor, Db, RepoView } from '../types'

const URL_RE = /https:\/\/claude\.ai\/(?:code\/)?artifact\/[A-Za-z0-9_-]+/

export type Repo = { key: string; name: string }
export type Key = 'j' | 'k' | 'h' | 'l'

export function extractUrl(result: unknown): string | undefined {
  return JSON.stringify(result ?? null).match(URL_RE)?.[0]
}

export function titleOf(html: string, path: string): string {
  return html.match(/<title>([^<]*)<\/title>/i)?.[1]?.trim() || path.split('/').pop() || path
}

export function repoOf(repo: { root: string; remote: string | null } | null): Repo {
  if (!repo) return { key: '', name: 'その他' }
  const slug = repo.remote?.match(/[:/]([^/:]+\/[^/]+?)(?:\.git)?$/)?.[1]
  return slug ? { key: slug, name: slug } : { key: repo.root, name: repo.root.split('/').pop() || repo.root }
}

export function record(db: Db, repo: Repo, a: Artifact): Db {
  const r = db[repo.key] ?? { name: repo.name, artifacts: [] }
  const artifacts = r.artifacts.some(x => x.url === a.url) ? r.artifacts.map(x => (x.url === a.url ? a : x)) : [...r.artifacts, a]
  return { ...db, [repo.key]: { name: repo.name, artifacts } }
}

export function view(db: Db, current: string): RepoView[] {
  return Object.entries(db)
    .filter(([, r]) => r.artifacts.length)
    .map(([key, r]) => {
      const artifacts = [...r.artifacts].sort((a, b) => b.at - a.at)
      return { key, name: r.name, at: artifacts[0]!.at, artifacts }
    })
    .sort((a, b) => Number(b.key === current) - Number(a.key === current) || b.at - a.at)
}

const clamp = (n: number, len: number) => Math.min(Math.max(n, 0), Math.max(len - 1, 0))

export function move(c: Cursor, key: Key, repos: RepoView[]): { cursor: Cursor; open?: string } {
  const items = repos[c.repo]?.artifacts ?? []
  if (c.col === 0) {
    if (key === 'j' || key === 'k') return { cursor: { col: 0, repo: clamp(c.repo + (key === 'j' ? 1 : -1), repos.length), item: 0 } }
    if (key === 'l' && items.length) return { cursor: { ...c, col: 1, item: 0 } }
    return { cursor: c }
  }
  if (key === 'j' || key === 'k') return { cursor: { ...c, item: clamp(c.item + (key === 'j' ? 1 : -1), items.length) } }
  if (key === 'h') return { cursor: { ...c, col: 0 } }
  return { cursor: c, open: items[c.item]?.url }
}
