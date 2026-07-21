import assert from 'node:assert/strict'
import test from 'node:test'
import { minimizeFailure } from './differential-minimizer.mjs'

test('minimizes a failure-inducing template to its essential token', () => {
  const result = minimizeFailure(
    {
      template: 'prefix {{BUG}} suffix',
      context: { noise: 'unused' },
      partials: { unused: 'noise' },
    },
    (fixture) => fixture.template.includes('BUG'),
  )
  assert.equal(result.fixture.template, 'BUG')
  assert.deepEqual(result.fixture.context, {})
  assert.deepEqual(result.fixture.partials, {})
  assert.ok(result.minimized_size < result.original_size)
})

test('prunes unrelated nested context while preserving the reproducer', () => {
  const result = minimizeFailure(
    {
      template: '{{value}}',
      context: {
        required: { trigger: true, noise: 'remove me' },
        unrelated: [1, 2, 3],
      },
      partials: {},
    },
    (fixture) => fixture.context?.required?.trigger === true,
  )
  assert.equal(result.fixture.context.required.trigger, true)
  assert.equal('noise' in result.fixture.context.required, false)
  assert.equal('unrelated' in result.fixture.context, false)
})

test('honors the evaluation budget', () => {
  const result = minimizeFailure(
    { template: 'abcdef', context: {}, partials: {} },
    () => true,
    { maxEvaluations: 2 },
  )
  assert.ok(result.evaluations <= 2)
})
