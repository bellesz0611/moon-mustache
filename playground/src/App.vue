<script setup>
import { computed, onMounted, ref, watch } from 'vue'
import Mustache from 'mustache'
import metrics from '../../docs/METRICS_SNAPSHOT.json'
import fixtureManifest from '../../third_party/mustache-spec/MANIFEST.json'
import { examples } from './examples'
import { generateMoonStarter, renderMoonMustache } from './generated/moon_mustache.js'

const activeTab = ref('render')
const locale = ref('zh')
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
const starterContextJson = ref(
  JSON.stringify(
    {
      package: 'example/moon-starter',
      display_name: 'Moon Starter',
      description: 'A generated MoonBit project with reproducible CI.',
    },
    null,
    2,
  ),
)
const starterFiles = ref([])
const starterErrors = ref([])
const starterMissingVariables = ref([])
const isGenerating = ref(false)

const copy = {
  zh: {
    eyebrow: '渲染 · 诊断 · 对比 · 规范',
    title: 'MoonBit 模板生成兼容性实验室',
    lead: '直接在浏览器运行仓库编译出的 MoonBit 引擎，编辑模板、JSON 上下文和 Partial，并在同一条可复现流程中检查输出、诊断、参考实现差异和官方规范证据。',
    render: '渲染 Render',
    diagnose: '诊断 Diagnose',
    compare: '对比 Compare',
    conformance: '规范 Conformance',
    generate: '生成 Generate',
    renderNow: '立即渲染',
    rendering: '渲染中…',
    clean: '当前渲染通过',
    attention: '发现诊断信息',
    noDiagnostics: '没有诊断信息，当前渲染结果正常。',
  },
  en: {
    eyebrow: 'Render · Diagnose · Compare · Conformance',
    title: 'A compatibility lab for MoonBit template generation',
    lead: 'Run the repository’s compiled MoonBit engine directly in the browser. Edit templates, JSON context, and partials, then inspect output, diagnostics, reference parity, and official conformance evidence in one reproducible flow.',
    render: 'Render',
    diagnose: 'Diagnose',
    compare: 'Compare',
    conformance: 'Conformance',
    generate: 'Generate',
    renderNow: 'Render now',
    rendering: 'Rendering…',
    clean: 'Current render is clean',
    attention: 'Diagnostics available',
    noDiagnostics: 'No diagnostics. The current render is clean.',
  },
}

const t = computed(() => copy[locale.value])
const tabs = computed(() => [
  { id: 'render', label: t.value.render },
  { id: 'diagnose', label: t.value.diagnose },
  { id: 'compare', label: t.value.compare },
  { id: 'conformance', label: t.value.conformance },
  { id: 'generate', label: t.value.generate },
])

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
  'python scripts/run_coverage.py --minimum 88 --cli-core-minimum 70',
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

async function generateStarter() {
  isGenerating.value = true
  try {
    const payload = JSON.parse(
      generateMoonStarter(starterContextJson.value, strictMissing.value),
    )
    starterFiles.value = payload.files || []
    starterErrors.value = payload.errors || []
    starterMissingVariables.value = payload.missing_variables || []
  } catch (error) {
    starterFiles.value = []
    starterMissingVariables.value = []
    starterErrors.value = [error instanceof Error ? error.message : String(error)]
  } finally {
    isGenerating.value = false
  }
}

const diagnosticsCount = computed(
  () => diagnostics.value.length + missingVariables.value.length + (lastError.value ? 1 : 0),
)

const healthTone = computed(() => {
  if (lastError.value || diagnosticsCount.value > 0) return 'attention'
  return 'clean'
})

const referenceResult = computed(() => {
  try {
    const context = JSON.parse(contextJson.value)
    const partials = JSON.parse(partialsJson.value)
    return {
      output: Mustache.render(template.value, context, partials),
      error: '',
    }
  } catch (error) {
    return {
      output: '',
      error: error instanceof Error ? error.message : String(error),
    }
  }
})

const outputsMatch = computed(
  () =>
    !lastError.value &&
    diagnostics.value.length === 0 &&
    !referenceResult.value.error &&
    output.value === referenceResult.value.output,
)

const conformanceSuites = computed(() =>
  fixtureManifest.fixtures.map(fixture => ({
    name: fixture.path.split('/').at(-1).replace('.json', ''),
    cases: fixture.tests,
    sha: fixture.sha256.slice(0, 12),
  })),
)

onMounted(() => {
  renderNow()
  generateStarter()
})
</script>

<template>
  <div class="shell">
    <header class="hero">
      <div class="hero-copy">
        <div class="hero-topline">
          <p class="eyebrow">{{ t.eyebrow }}</p>
          <button class="locale-toggle" type="button" @click="locale = locale === 'zh' ? 'en' : 'zh'">
            {{ locale === 'zh' ? 'EN' : '中文' }}
          </button>
        </div>
        <h1>{{ t.title }}</h1>
        <p class="lead">{{ t.lead }}</p>
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

    <nav class="lab-tabs" aria-label="Compatibility lab views">
      <button
        v-for="tab in tabs"
        :key="tab.id"
        type="button"
        class="lab-tab"
        :class="{ active: activeTab === tab.id }"
        :aria-selected="activeTab === tab.id"
        @click="activeTab = tab.id"
      >
        {{ tab.label }}
      </button>
    </nav>

    <main class="lab-view">
      <template v-if="activeTab === 'render'">
        <section class="toolbar">
          <div class="chips">
            <button
              v-for="example in examples"
              :key="example.id"
              type="button"
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
            <button class="render-button" type="button" @click="renderNow">
              {{ isRendering ? t.rendering : t.renderNow }}
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
                <span>MoonBit rendered text</span>
              </div>
              <button class="ghost-button" type="button" @click="copyOutput">
                {{ copied || 'Copy output' }}
              </button>
            </div>
            <pre>{{ output }}</pre>
          </article>
        </section>
      </template>

      <section v-else-if="activeTab === 'diagnose'" class="status-grid">
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
          <p v-else class="status-ok">{{ t.noDiagnostics }}</p>
        </article>

        <article class="status-card">
          <div class="status-head">
            <h3>Checked-render contract</h3>
            <span :class="['signal-dot', healthTone]"></span>
          </div>
          <ul class="status-list">
            <li>Strict missing-variable collection: {{ strictMissing ? 'enabled' : 'disabled' }}</li>
            <li>Parser/render errors: {{ diagnostics.length }}</li>
            <li>Missing variables: {{ missingVariables.length }}</li>
            <li>Runtime or JSON errors: {{ lastError ? 1 : 0 }}</li>
            <li>The engine preserves rendered output while returning diagnostics separately.</li>
          </ul>
        </article>
      </section>

      <section v-else-if="activeTab === 'compare'" class="compare-view">
        <div :class="['parity-banner', outputsMatch ? 'clean' : 'attention']">
          <strong>{{ outputsMatch ? 'Outputs match' : 'Outputs differ or input is invalid' }}</strong>
          <span>Moon Mustache vs mustache.js {{ Mustache.version }}</span>
        </div>
        <div class="compare-grid">
          <article class="panel output-panel">
            <div class="panel-head">
              <h2>Moon Mustache</h2>
              <span>Compiled MoonBit ES module</span>
            </div>
            <pre>{{ output }}</pre>
          </article>
          <article class="panel reference-panel">
            <div class="panel-head">
              <h2>mustache.js</h2>
              <span>Reference {{ Mustache.version }}</span>
            </div>
            <pre>{{ referenceResult.error || referenceResult.output }}</pre>
          </article>
        </div>
        <p class="view-note">
          This is an immediate single-input comparison. The reproducible seeded differential suite runs
          {{ verification.differential_policy.cases }} generated cases in CI and emits JSON plus JUnit evidence.
        </p>
      </section>

      <section v-else-if="activeTab === 'conformance'" class="conformance-view">
        <div class="conformance-summary">
          <div>
            <span class="proof-kicker">Pinned official corpus</span>
            <h2>{{ verification.official_fixtures.passed }} / {{ verification.official_fixtures.total }} passing</h2>
            <p>
              {{ conformanceSuites.length }} suites from mustache/spec commit
              <code>{{ fixtureManifest.upstream.commit.slice(0, 12) }}</code>. Case counts and hashes below are
              loaded from the repository manifest at build time.
            </p>
          </div>
          <a class="hero-link primary" href="https://github.com/bellesz0611/moon-mustache/blob/main/docs/OFFICIAL_SPEC.md" target="_blank" rel="noreferrer">
            Inspect reproduction guide
          </a>
        </div>
        <div class="table-wrap">
          <table class="conformance-table">
            <thead>
              <tr>
                <th>Suite</th>
                <th>Cases</th>
                <th>Fixture SHA-256</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="suite in conformanceSuites" :key="suite.name">
                <td>{{ suite.name }}</td>
                <td>{{ suite.cases }}</td>
                <td><code>{{ suite.sha }}…</code></td>
              </tr>
            </tbody>
          </table>
        </div>
      </section>

      <section v-else class="generator-view">
        <article class="generator-control">
          <div>
            <span class="proof-kicker">Checked TemplateBundle task</span>
            <h2>Generate a reviewable MoonBit starter</h2>
            <p>
              Edit one structured context, then run the repository’s MoonBit bundle API to produce five
              in-memory artifacts. No files are written by the browser.
            </p>
          </div>
          <button class="render-button" type="button" @click="generateStarter">
            {{ isGenerating ? 'Generating…' : 'Generate project' }}
          </button>
        </article>
        <article class="panel generator-context">
          <div class="panel-head">
            <h2>Project context</h2>
            <span>Strict JSON input</span>
          </div>
          <textarea v-model="starterContextJson" spellcheck="false"></textarea>
        </article>
        <div v-if="starterErrors.length || starterMissingVariables.length" class="generator-errors">
          <strong>Generation blocked</strong>
          <ul class="status-list">
            <li v-for="error in starterErrors" :key="error">{{ error }}</li>
            <li v-for="name in starterMissingVariables" :key="name">missing variable: {{ name }}</li>
          </ul>
        </div>
        <div v-else class="artifact-grid">
          <article v-for="file in starterFiles" :key="file.path" class="panel artifact-card">
            <div class="panel-head">
              <h2>{{ file.path }}</h2>
              <span>{{ file.output.length }} chars</span>
            </div>
            <pre>{{ file.output || '(empty package configuration)' }}</pre>
          </article>
        </div>
      </section>
    </main>

    <section class="use-case-grid">
      <article v-for="item in useCases" :key="item.title" class="use-case-card">
        <h3>{{ item.title }}</h3>
        <p>{{ item.body }}</p>
      </article>
    </section>
  </div>
</template>
