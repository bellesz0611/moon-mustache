# Moon Mustache Playground

This directory contains a Vue + Vite playground for Moon Mustache.

## What it does

- edits Mustache templates in the browser
- edits JSON context and partials side by side
- renders through the repository's own MoonBit engine
- surfaces diagnostics and missing variables without switching back to the CLI
- bundles current test and coverage values from `docs/METRICS_SNAPSHOT.json`

## Run locally

```bash
cd playground
npm install
npm run dev
```

This starts a Vite front-end on port `5173`. The build step compiles `browser_bridge/` into an ES module, and the browser calls that MoonBit module directly without an online backend.

## Build the front-end

```bash
npm run build
```

## Run the automated smoke test

```bash
npm run smoke
```

This script independently starts the local `playground_bridge/` API, waits for its health endpoint, submits a real render request, and verifies the returned output. It covers the API integration path in addition to the browser's direct ES-module path. Both are exercised by the dedicated GitHub Actions `playground` workflow.

## Notes

- the playground is a product-facing compatibility lab for render, diagnostics, and verification evidence
- file-backed rendering is still handled by the main CLI
- the bridge uses the MoonBit build output instead of a third-party Mustache implementation
