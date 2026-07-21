import fs from 'node:fs'
import path from 'node:path'
import Mustache from 'mustache'
import { renderMoonMustache } from '../src/generated/moon_mustache.js'

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

function writeJson(filePath, payload) {
  if (!filePath) return
  const resolved = path.resolve(filePath)
  fs.mkdirSync(path.dirname(resolved), { recursive: true })
  fs.writeFileSync(resolved, `${JSON.stringify(payload, null, 2)}\n`, 'utf8')
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

function evaluate(seed, index, test) {
  const expected = Mustache.render(test.template, test.context, test.partials)
  const response = JSON.parse(
    renderMoonMustache(
      test.template,
      JSON.stringify(test.context),
      JSON.stringify(test.partials),
      false,
    ),
  )
  if (response.errors.length === 0 && response.output === expected) return undefined
  return {
    seed,
    index,
    fixture: test,
    expected,
    actual: response.output,
    errors: response.errors,
    reproduce: `node scripts/differential-test.mjs --seed ${seed} --cases ${index + 1} --case-index ${index}`,
  }
}

const started = performance.now()
const failures = []
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
    if (failures.length >= maxFailures) break
  }
  if (failures.length >= maxFailures) break
}

const report = {
  schema_version: 1,
  suite: 'moon-mustache differential parity',
  reference: `mustache.js ${Mustache.version ?? 'unknown'}`,
  seeds,
  cases_per_seed: casesPerSeed,
  requested_case_index: caseIndex ?? null,
  passed: executed - failures.length,
  total: executed,
  duration_ms: Math.round(performance.now() - started),
  failures,
}

writeJson(jsonOutput, report)
if (failures.length > 0) {
  writeJson(failureOutput, report)
  console.error(`Differential parity failed: ${failures.length}/${executed} cases`)
  for (const failure of failures) {
    console.error(`- seed ${failure.seed}, case ${failure.index}`)
    console.error(`  reproduce: ${failure.reproduce}`)
  }
  process.exitCode = 1
} else {
  console.log(
    `Differential parity: ${executed}/${executed} cases passed ` +
      `(seeds ${seeds.join(', ')}, reference ${report.reference})`,
  )
  if (jsonOutput) console.log(`Report: ${path.resolve(jsonOutput)}`)
}
