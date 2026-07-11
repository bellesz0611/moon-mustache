import Mustache from 'mustache'
import { renderMoonMustache } from '../src/generated/moon_mustache.js'

function option(name, fallback) {
  const index = process.argv.indexOf(name)
  return index >= 0 && process.argv[index + 1] ? Number(process.argv[index + 1]) : fallback
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

const cases = option('--cases', 2048)
const seed = option('--seed', 20260710)
const random = mulberry32(seed)
const words = ['MoonBit', 'Mustache', 'template', 'release', 'alpha', 'beta', '<tag>', 'A&B']

function pick(items) {
  return items[Math.floor(random() * items.length)]
}

function integer(maximum) {
  return Math.floor(random() * maximum)
}

function fixture(index) {
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

const failures = []
for (let index = 0; index < cases; index += 1) {
  const test = fixture(index)
  const expected = Mustache.render(test.template, test.context, test.partials)
  const response = JSON.parse(
    renderMoonMustache(
      test.template,
      JSON.stringify(test.context),
      JSON.stringify(test.partials),
      false,
    ),
  )
  if (response.errors.length > 0 || response.output !== expected) {
    failures.push({ index, test, expected, actual: response.output, errors: response.errors })
    if (failures.length >= 10) break
  }
}

if (failures.length > 0) {
  console.error(JSON.stringify({ seed, cases, failures }, null, 2))
  process.exitCode = 1
} else {
  console.log(`Differential parity: ${cases}/${cases} cases passed (seed ${seed})`)
}
