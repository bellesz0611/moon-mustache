import assert from 'node:assert/strict'
import fs from 'node:fs'
import os from 'node:os'
import path from 'node:path'
import { spawnSync } from 'node:child_process'
import test from 'node:test'
import { fileURLToPath } from 'node:url'

const scriptDirectory = path.dirname(fileURLToPath(import.meta.url))
const differentialScript = path.join(scriptDirectory, 'differential-test.mjs')

test('writes an automatically minimized reproducer for a real pipeline failure', () => {
  const temporaryDirectory = fs.mkdtempSync(path.join(os.tmpdir(), 'moon-mustache-diff-test-'))
  try {
    const enginePath = path.join(temporaryDirectory, 'faulty-engine.mjs')
    const reportPath = path.join(temporaryDirectory, 'failures.json')
    fs.writeFileSync(
      enginePath,
      "export function renderMoonMustache() { return JSON.stringify({ output: 'forced mismatch', errors: [], missing_variables: [] }) }\n",
      'utf8',
    )
    const result = spawnSync(
      process.execPath,
      [
        differentialScript,
        '--seed',
        '20260710',
        '--cases',
        '1',
        '--max-failures',
        '1',
        '--engine-module',
        enginePath,
        '--failure-output',
        reportPath,
      ],
      { encoding: 'utf8' },
    )
    assert.equal(result.status, 1)
    const report = JSON.parse(fs.readFileSync(reportPath, 'utf8'))
    assert.equal(report.failures.length, 1)
    const failure = report.failures[0]
    assert.equal(failure.failure_kind, 'output-mismatch')
    assert.equal(failure.minimized.failure_kind, 'output-mismatch')
    assert.ok(failure.minimized.minimized_size < failure.minimized.original_size)
    assert.equal(failure.minimized.fixture.template, '')
    assert.deepEqual(failure.minimized.fixture.context, {})
    assert.deepEqual(failure.minimized.fixture.partials, {})
  } finally {
    fs.rmSync(temporaryDirectory, { recursive: true, force: true })
  }
})
