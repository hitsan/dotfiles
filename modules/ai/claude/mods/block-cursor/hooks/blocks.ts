export type Segment = { raw: string; copy: string }

const FENCE = /^\s*(```|~~~)/

export function segments(text: string): Segment[] {
  const lines = text.split('\n')
  const out: Segment[] = []
  let plain: string[] = []
  const flush = () => {
    if (plain.length) out.push({ raw: plain.join('\n'), copy: plain.join('\n') })
    plain = []
  }

  for (let i = 0; i < lines.length; ) {
    const line = lines[i]!
    const open = line.match(FENCE)
    if (open) {
      let end = i + 1
      while (end < lines.length && !lines[end]!.trimStart().startsWith(open[1]!)) end++
      flush()
      out.push({ raw: lines.slice(i, end + 1).join('\n'), copy: lines.slice(i + 1, end).join('\n') })
      i = end + 1
    } else if (line.startsWith('>')) {
      let end = i
      while (end < lines.length && lines[end]!.startsWith('>')) end++
      flush()
      const quote = lines.slice(i, end)
      out.push({ raw: quote.join('\n'), copy: quote.map(l => l.replace(/^> ?/, '')).join('\n') })
      i = end
    } else {
      if (line.trim()) plain.push(line)
      else flush()
      i++
    }
  }
  flush()
  return out
}
