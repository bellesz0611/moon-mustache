import assert from 'node:assert/strict'
import test from 'node:test'

import { buildEvidenceLayers, buildMutationRows } from '../src/evidence.js'

test('builds judge-facing evidence from generated metrics instead of fixed totals', () => {
  const verification = {
    fault_injection: {
      killed: 3,
      total: 4,
      survived: 1,
      invalid: 0,
      mutations: [],
    },
    differential_policy: {
      cases: 321,
      seeds: [7, 8],
      reference: 'reference-engine',
    },
    backend_conformance: {
      results: [{ status: 'passed' }, { status: 'failed' }],
    },
    cli_integration: { passed: 9, total: 10 },
  }

  const layers = buildEvidenceLayers(verification)
  assert.equal(layers[0].value, '3 / 4 killed')
  assert.match(layers[0].note, /1 survived/)
  assert.equal(layers[1].value, '321 generated cases')
  assert.match(layers[1].note, /2 fixed seeds against reference-engine/)
  assert.equal(layers[2].value, '1 / 2 local targets')
  assert.equal(layers[3].value, '9 / 10 passing')
})

test('exposes each mutant risk and focused detector without wildcard noise', () => {
  const rows = buildMutationRows({
    mutations: [
      {
        name: 'disable guard',
        risk: 'unbounded work',
        test_filter: '*resource limit is enforced*',
        status: 'killed',
      },
    ],
  })

  assert.deepEqual(rows, [
    {
      name: 'disable guard',
      risk: 'unbounded work',
      detector: 'resource limit is enforced',
      status: 'killed',
    },
  ])
})
