import fs from 'node:fs'
import path from 'node:path'
import { pathToFileURL } from 'node:url'
import Mustache from 'mustache'
import { minimizeFailure } from './differential-minimizer.mjs'

function option(name) {
  const index = process.argv.lastIndexOf(name)
  return index >= 0 && process.argv[index + 1] ? process.argv[index + 1] : undefined
}

function numberOption(name, fallback) {
  const raw = option(name)
  if (raw === undefined) return fallback
  const value = Number(raw)
  if (!Number.isInteger(value) || value < 0) {
    throw new Error(`${name} must be a non-negative integer`)
  }
  return value
}

function seedList() {
  const raw = option('--seeds') ?? option('--seed') ?? '20260710,20260711,20260712,20260713'
  const seeds = raw.split(',').map((item) => Number(item.trim()))
  if (seeds.length === 0 || seeds.some((seed) => !Number.isInteger(seed))) {
    throw new Error('--seeds must be a comma-separated list of integers')
  }
  return seeds
}

const engineModule = option('--engine-module')
const engineUrl = engineModule
  ? pathToFileURL(path.resolve(engineModule)).href
  : new URL('../src/generated/moon_mustache.js', import.meta.url).href
const { renderMoonMustache } = await import(engineUrl)
if (typeof renderMoonMustache !== 'function') {
  throw new Error(`engine module does not export renderMoonMustache: ${engineUrl}`)
}

function writeJson(filePath, payload) {
  if (!filePath) return
  const resolved = path.resolve(filePath)
  fs.mkdirSync(path.dirname(resolved), { recursive: true })
  fs.writeFileSync(resolved, `${JSON.stringify(payload, null, 2)}\n`, 'utf8')
}

function xmlEscape(value) {
  return String(value)
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
}

function writeJUnit(filePath, executions, report) {
  if (!filePath) return
  const cases = executions.map(({ seed, index, failure }) => {
    const header = `  <testcase classname="seed-${seed}" name="case-${index}">`
    if (!failure) return `${header}</testcase>`
    const details = xmlEscape(JSON.stringify(failure, null, 2))
    return `${header}<failure message="differential output mismatch">${details}</failure></testcase>`
  })
  const xml = [
    '<?xml version="1.0" encoding="UTF-8"?>',
    `<testsuite name="moon-mustache differential parity" tests="${report.total}" failures="${report.failures.length}" time="${(report.duration_ms / 1000).toFixed(3)}">`,
    ...cases,
    '</testsuite>',
    '',
  ].join('\n')
  const resolved = path.resolve(filePath)
  fs.mkdirSync(path.dirname(resolved), { recursive: true })
  fs.writeFileSync(resolved, xml, 'utf8')
}

function mulberry32(seed) {
  return () => {
    seed |= 0
    seed = (seed + 0x6d2b79f5) | 0
    let value = Math.imul(seed ^ (seed >>> 15), 1 | seed)
    value = (value + Math.imul(value ^ (value >>> 7), 61 | value)) ^ value
    return ((value ^ (value >>> 14)) >>> 0) / 4294967296
  }
}

const casesPerSeed = numberOption('--cases-per-seed', numberOption('--cases', 512))
const seeds = seedList()
const caseIndex = option('--case-index') === undefined ? undefined : numberOption('--case-index', 0)
const maxFailures = numberOption('--max-failures', 10)
const jsonOutput = option('--json-output')
const failureOutput = option('--failure-output')
const junitOutput = option('--junit-output')
const minimizeFailures = !process.argv.includes('--no-minimize')
const maxMinimizerEvaluations = numberOption('--max-minimizer-evaluations', 250)
const words = ['MoonBit', 'Mustache', 'template', 'release', 'alpha', 'beta', '<tag>', 'A&B']

function fixture(index, random) {
  const pick = (items) => items[Math.floor(random() * items.length)]
  const integer = (maximum) => Math.floor(random() * maximum)
  const name = `${pick(words)}-${integer(1000)}`
  const html = `<strong>${pick(words)} & ${integer(100)}</strong>`
  const enabled = random() >= 0.5
  const itemCount = integer(5)
  const items = Array.from({ length: itemCount }, (_, itemIndex) => ({
    name: `${pick(words)}-${itemIndex}`,
    value: integer(500),
  }))

  switch (index % 9) {
    case 0:
      return { template: 'Hello {{name}}!', context: { name }, partials: {} }
    case 1:
      return { template: '{{{html}}}|{{html}}|{{& html}}', context: { html }, partials: {} }
    case 2:
      return {
        template: '{{#enabled}}yes:{{name}}{{/enabled}}{{^enabled}}no{{/enabled}}',
        context: { enabled, name },
        partials: {},
      }
    case 3:
      return {
        template: '{{#items}}[{{name}}={{value}}]{{/items}}{{^items}}empty{{/items}}',
        context: { items },
        partials: {},
      }
    case 4:
      return {
        template: '{{user.profile.name}}/{{user.profile.rank}}/{{missing}}',
        context: { user: { profile: { name, rank: integer(20) } } },
        partials: {},
      }
    case 5:
      return {
        template: 'begin\n  {{> card}}\nend',
        context: { name, value: integer(100) },
        partials: { card: '{{name}}\nvalue={{value}}' },
      }
    case 6:
      return {
        template: '{{=<% %>=}}<%name%>|<%#enabled%>on<%/enabled%><%^enabled%>off<%/enabled%>',
        context: { name, enabled },
        partials: {},
      }
    case 7:
      return {
        template: 'A{{! generated comment }}B {{#user}}{{name}}/{{../ignored}}{{/user}}',
        context: { user: { name } },
        partials: {},
      }
    default:
      return {
        template: '{{#outer}}{{#items}}{{prefix}}:{{name}};{{/items}}{{^items}}none{{/items}}{{/outer}}',
        context: { outer: { prefix: pick(words), items } },
        partials: {},
      }
  }
}

function compare(test) {
  let expected
  try {
    expected = Mustache.render(test.template, test.context, test.partials)
  } catch (error) {
    return {
      kind: 'reference-error',
      expected: '',
      actual: '',
      errors: [error instanceof Error ? error.message : String(error)],
    }
  }
  const response = JSON.parse(
    renderMoonMustache(
      test.template,
      JSON.stringify(test.context),
      JSON.stringify(test.partials),
      false,
    ),
  )
  if (response.errors.length > 0) {
    return {
      kind: 'moon-diagnostic',
      expected,
      actual: response.output,
      errors: response.errors,
    }
  }
  if (response.output !== expected) {
    return {
      kind: 'output-mismatch',
      expected,
      actual: response.output,
      errors: [],
    }
  }
  return undefined
}

function evaluate(seed, index, test) {
  const comparison = compare(test)
  if (!comparison) return undefined
  let minimized
  if (minimizeFailures) {
    const result = minimizeFailure(
      test,
      (candidate) => compare(candidate)?.kind === comparison.kind,
      { maxEvaluations: maxMinimizerEvaluations },
    )
    const minimizedComparison = compare(result.fixture)
    minimized = {
      ...result,
      failure_kind: minimizedComparison.kind,
      expected: minimizedComparison.expected,
      actual: minimizedComparison.actual,
      errors: minimizedComparison.errors,
    }
  }
  return {
    seed,
    index,
    failure_kind: comparison.kind,
    fixture: test,
    expected: comparison.expected,
    actual: comparison.actual,
    errors: comparison.errors,
    minimized,
    reproduce: `node scripts/differential-test.mjs --seed ${seed} --cases ${index + 1} --case-index ${index}`,
  }
}

const started = performance.now()
const failures = []
const executions = []
let executed = 0
for (const seed of seeds) {
  const random = mulberry32(seed)
  const limit = caseIndex === undefined ? casesPerSeed : Math.max(casesPerSeed, caseIndex + 1)
  for (let index = 0; index < limit; index += 1) {
    const test = fixture(index, random)
    if (caseIndex !== undefined && index !== caseIndex) continue
    executed += 1
    const failure = evaluate(seed, index, test)
    if (failure) failures.push(failure)
    executions.push({ seed, index, failure })
    if (failures.length >= maxFailures) break
  }
  if (failures.length >= maxFailures) break
}

const report = {
  schema_version: 2,
  suite: 'moon-mustache differential parity',
  reference: `mustache.js ${Mustache.version ?? 'unknown'}`,
  seeds,
  cases_per_seed: casesPerSeed,
  requested_case_index: caseIndex ?? null,
  minimization: {
    enabled: minimizeFailures,
    max_evaluations_per_failure: maxMinimizerEvaluations,
  },
  passed: executed - failures.length,
  total: executed,
  duration_ms: Math.round(performance.now() - started),
  failures,
}

writeJson(jsonOutput, report)
writeJUnit(junitOutput, executions, report)
if (failures.length > 0) {
  writeJson(failureOutput, report)
  console.error(`Differential parity failed: ${failures.length}/${executed} cases`)
  for (const failure of failures) {
    console.error(`- seed ${failure.seed}, case ${failure.index}`)
    console.error(`  reproduce: ${failure.reproduce}`)
    if (failure.minimized) {
      console.error(
        `  minimized: ${failure.minimized.original_size} -> ${failure.minimized.minimized_size} JSON chars ` +
          `in ${failure.minimized.evaluations} evaluations`,
      )
    }
  }
  process.exitCode = 1
} else {
  console.log(
    `Differential parity: ${executed}/${executed} cases passed ` +
      `(seeds ${seeds.join(', ')}, reference ${report.reference})`,
  )
  if (jsonOutput) console.log(`Report: ${path.resolve(jsonOutput)}`)
}
