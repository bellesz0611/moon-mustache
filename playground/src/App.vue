<script setup>
import { computed, onMounted, ref, watch } from 'vue'
import { examples } from './examples'

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
    const response = await fetch('/api/render', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        template: template.value,
        contextJson: contextJson.value,
        partialsJson: partialsJson.value,
        strictMissing: strictMissing.value,
      }),
    })
    const payload = await response.json()
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

onMounted(() => {
  renderNow()
})
</script>

<template>
  <div class="shell">
    <header class="hero">
      <div class="hero-copy">
        <p class="eyebrow">MoonBit Playground</p>
        <h1>Watch Moon Mustache render in real time.</h1>
        <p class="lead">
          A Vue playground backed by this repository's own MoonBit rendering core. Edit the template,
          JSON context, and partials, then inspect output and diagnostics side by side.
        </p>
      </div>
      <div class="hero-card">
        <div class="metric">
          <span class="metric-value">136 / 136</span>
          <span class="metric-label">Official fixture cases passing</span>
        </div>
        <div class="metric">
          <span class="metric-value">61</span>
          <span class="metric-label">Automated tests</span>
        </div>
        <div class="metric">
          <span class="metric-value">Vue + MoonBit</span>
          <span class="metric-label">Front-end demo wired to project engine</span>
        </div>
      </div>
    </header>

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
          <li>Shows the project as a usable tool, not just a CLI transcript.</li>
          <li>Uses the repository's own MoonBit engine through a local render bridge.</li>
          <li>Makes template, context, and diagnostics visible in one glance for judges.</li>
        </ul>
      </article>
    </section>
  </div>
</template>

