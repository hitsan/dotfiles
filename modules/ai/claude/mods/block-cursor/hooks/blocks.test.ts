import { expect, test } from 'claude-code/testing'

import { segments } from './blocks'

test('a code fence copies its body', async () => {
  expect(segments('```sh\nls -la\npwd\n```')).toEqual([{ raw: '```sh\nls -la\npwd\n```', copy: 'ls -la\npwd' }])
})

test('a run of quote lines copies without the markers', async () => {
  expect(segments('> one\n>two')).toEqual([{ raw: '> one\n>two', copy: 'one\ntwo' }])
})

test('paragraphs split on blank lines', async () => {
  expect(segments('hello\nworld\n\nnext')).toEqual([
    { raw: 'hello\nworld', copy: 'hello\nworld' },
    { raw: 'next', copy: 'next' },
  ])
})

test('blank lines inside a fence stay in it', async () => {
  expect(segments('```\na\n\nb\n```').map(s => s.copy)).toEqual(['a\n\nb'])
})

test('mixed text keeps its order', async () => {
  expect(segments('intro\n~~~\nx\n~~~\nmid\n> q\nend').map(s => s.copy)).toEqual(['intro', 'x', 'mid', 'q', 'end'])
})

test('an unclosed fence runs to the end', async () => {
  expect(segments('```\na\nb')).toEqual([{ raw: '```\na\nb', copy: 'a\nb' }])
})
