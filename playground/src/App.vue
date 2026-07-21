<script setup>
import { computed, onMounted, ref, watch } from 'vue'
import metrics from '../../docs/METRICS_SNAPSHOT.json'
import { examples } from './examples'
import { renderMoonMustache } from './generated/moon_mustache.js'

const selectedId = ref(examples[0].id)
const template = ref(examples[0].template)
const contextJson = ref(examples[0].contextJson)
const partialsJson = ref(examples[0].partialsJson)
const strictMissing = ref(true)
const autoRender = ref(true)
const isRendering = ref(false)
const output = ref('')
const diagnostics = ref([])
const missingVariables = ref([])
const lastError = ref('')
const copied = ref('')

const verification = metrics.verification
const proofItems = [
  {
    label: 'Official fixtures',
    value: `${verification.official_fixtures.passed} / ${verification.official_fixtures.total}`,
    note: 'Core and optional mustache/spec cases passing end to end.',
  },
  {
    label: 'MoonBit tests',
    value: `${verification.moon_tests.passed} / ${verification.moon_tests.total}`,
    note: 'Unit, regression, failure-contract, and executable documentation tests.',
  },
  {
    label: 'Core coverage',
    value: `${verification.core_coverage.percent}%`,
    note: `${verification.core_coverage.covered} / ${verification.core_coverage.total} instrumentation points; ${verification.core_coverage.gate_percent}% CI gate.`,
  },
  {
    label: 'Differential parity',
    value: `${verification.differential_policy.cases} / ${verification.differential_policy.cases}`,
    note: `${verification.differential_policy.seeds.length} fixed seeds against ${verification.differential_policy.reference}.`,
  },
  {
    label: 'CLI integration',
    value: `${verification.cli_integration.passed} / ${verification.cli_integration.total}`,
    note: 'Real subprocess output, exit codes, file IO, lint, and bundle artifacts.',
  },
]

const useCases = [
  {
    title: 'Scaffolding',
    body: 'Generate starter projects, config files, and documentation bundles from one structured context.',
  },
  {
    title: 'Config Rendering',
    body: 'Render deployment manifests, local overrides, and machine-readable text output with strict diagnostics.',
  },
  {
    title: 'Template Analysis',
    body: 'Scan variables and partial references before integration to catch missing fields earlier in CI.',
  },
  {
    title: 'Downstream Embedding',
    body: 'Use the same core engine from other MoonBit packages instead of rebuilding string generation ad hoc.',
  },
]

const verificationPath = [
  'python scripts/verify.py --profile full',
  'python scripts/run_coverage.py --minimum 88',
  'moon run official_spec_report',
  'cd playground && npm run differential',
]

function applyExample(exampleId) {
  const selected = examples.find(example => example.id === exampleId)
  if (!selected) return
  selectedId.value = selected.id
  template.value = selected.template
  contextJson.value = selected.contextJson
  partialsJson.value = selected.partialsJson
}

async function renderNow() {
  isRendering.value = true
  lastError.value = ''
  try {
    const payload = JSON.parse(
      renderMoonMustache(
        template.value,
        contextJson.value,
        partialsJson.value,
        strictMissing.value,
      ),
    )
    output.value = payload.output || ''
    diagnostics.value = payload.errors || []
    missingVariables.value = payload.missing_variables || []
  } catch (error) {
    output.value = ''
    diagnostics.value = []
    missingVariables.value = []
    lastError.value = error instanceof Error ? error.message : String(error)
  } finally {
    isRendering.value = false
  }
}

let debounceTimer = null
watch([template, contextJson, partialsJson, strictMissing, autoRender], () => {
  if (!autoRender.value) return
  clearTimeout(debounceTimer)
  debounceTimer = setTimeout(() => {
    renderNow()
  }, 220)
})

async function copyOutput() {
  await navigator.clipboard.writeText(output.value)
  copied.value = 'Copied'
  setTimeout(() => {
    copied.value = ''
  }, 1200)
}

const diagnosticsCount = computed(
  () => diagnostics.value.length + missingVariables.value.length + (lastError.value ? 1 : 0),
)

const healthTone = computed(() => {
  if (lastError.value || diagnosticsCount.value > 0) return 'attention'
  return 'clean'
})

onMounted(() => {
  renderNow()
})
</script>

<template>
  <div class="shell">
    <header class="hero">
      <div class="hero-copy">
        <p class="eyebrow">Render · Diagnose · Verify</p>
        <h1>A compatibility lab for MoonBit template generation.</h1>
        <p class="lead">
          This playground runs the repository's MoonBit engine directly in the browser as a compiled ES module.
          Edit the template, JSON context, and partials, then inspect output, diagnostics, and integration
          signals side by side.
        </p>
        <div class="hero-actions">
          <a class="hero-link primary" href="https://github.com/bellesz0611/moon-mustache" target="_blank" rel="noreferrer">
            View repository
          </a>
          <a class="hero-link" href="https://mooncakes.io/package/bellesz0611/moon-mustache" target="_blank" rel="noreferrer">
            Open mooncakes package
          </a>
          <a class="hero-link" href="https://github.com/bellesz0611/moon-mustache/blob/main/docs/METRICS_SNAPSHOT.md" target="_blank" rel="noreferrer">
            Inspect test evidence
          </a>
        </div>
      </div>
      <div class="hero-card">
        <div v-for="item in proofItems" :key="item.label" class="metric">
          <span class="metric-value">{{ item.value }}</span>
          <span class="metric-label">{{ item.label }}</span>
          <span class="metric-note">{{ item.note }}</span>
        </div>
        <p class="evidence-source">
          Metrics are bundled from the repository's generated evidence snapshot, not copied into this page by hand.
        </p>
      </div>
    </header>

    <section class="proof-strip">
      <article class="proof-card">
        <span class="proof-kicker">Reproduce evidence</span>
        <h2>One-command verification</h2>
        <ol class="command-list">
          <li v-for="command in verificationPath" :key="command">
            <code>{{ command }}</code>
          </li>
        </ol>
      </article>
      <article class="proof-card">
        <span class="proof-kicker">Why this matters</span>
        <h2>More than a string formatter</h2>
        <p>
          Moon Mustache covers rendering, diagnostics, bundle planning, official compatibility fixtures,
          CLI usage, downstream embedding, and machine-readable verification artifacts.
        </p>
      </article>
      <article class="proof-card">
        <span class="proof-kicker">Status</span>
        <h2 :class="['health-pill', healthTone]">
          {{ healthTone === 'clean' ? 'Current render is clean' : 'Diagnostics available' }}
        </h2>
        <p>
          Toggle strict missing-variable checks, inspect partial usage, and verify how the engine responds
          before wiring it into a scaffold, config pipeline, or static content flow.
        </p>
      </article>
    </section>

    <section class="toolbar">
      <div class="chips">
        <button
          v-for="example in examples"
          :key="example.id"
          class="chip"
          :class="{ active: selectedId === example.id }"
          @click="applyExample(example.id)"
        >
          {{ example.name }}
        </button>
      </div>
      <div class="toggles">
        <label class="toggle">
          <input v-model="strictMissing" type="checkbox" />
          <span>Strict missing</span>
        </label>
        <label class="toggle">
          <input v-model="autoRender" type="checkbox" />
          <span>Auto render</span>
        </label>
        <button class="render-button" @click="renderNow">
          {{ isRendering ? 'Rendering...' : 'Render now' }}
        </button>
      </div>
    </section>

    <section class="workspace">
      <article class="panel">
        <div class="panel-head">
          <h2>Template</h2>
          <span>Mustache source</span>
        </div>
        <textarea v-model="template" spellcheck="false"></textarea>
      </article>

      <article class="panel">
        <div class="panel-head">
          <h2>Context JSON</h2>
          <span>Structured input</span>
        </div>
        <textarea v-model="contextJson" spellcheck="false"></textarea>
      </article>

      <article class="panel">
        <div class="panel-head">
          <h2>Partials JSON</h2>
          <span>Reusable fragments</span>
        </div>
        <textarea v-model="partialsJson" spellcheck="false"></textarea>
      </article>

      <article class="panel output-panel">
        <div class="panel-head">
          <div>
            <h2>Output</h2>
            <span>Rendered text</span>
          </div>
          <button class="ghost-button" @click="copyOutput">
            {{ copied || 'Copy output' }}
          </button>
        </div>
        <pre>{{ output }}</pre>
      </article>
    </section>

    <section class="use-case-grid">
      <article v-for="item in useCases" :key="item.title" class="use-case-card">
        <h3>{{ item.title }}</h3>
        <p>{{ item.body }}</p>
      </article>
    </section>

    <section class="status-grid">
      <article class="status-card">
        <div class="status-head">
          <h3>Diagnostics</h3>
          <span>{{ diagnosticsCount }}</span>
        </div>
        <ul v-if="diagnostics.length || missingVariables.length || lastError" class="status-list">
          <li v-if="lastError">{{ lastError }}</li>
          <li v-for="message in diagnostics" :key="message">{{ message }}</li>
          <li v-for="name in missingVariables" :key="name">missing variable: {{ name }}</li>
        </ul>
        <p v-else class="status-ok">No diagnostics. The current render is clean.</p>
      </article>

      <article class="status-card">
        <div class="status-head">
          <h3>Why this demo matters</h3>
        </div>
        <ul class="status-list">
          <li>Shows the project as a usable product surface, not just a CLI transcript.</li>
          <li>Uses the repository's own MoonBit engine through a local render bridge.</li>
          <li>Makes template, context, output, and diagnostics visible in one reproducible workflow.</li>
          <li>Gives downstream users a low-friction place to evaluate behavior before adopting the library.</li>
          <li>Loads test and coverage values from the canonical generated metrics snapshot at build time.</li>
        </ul>
      </article>
    </section>
  </div>
</template>
