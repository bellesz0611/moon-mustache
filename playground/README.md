# Moon Mustache Playground

This directory contains a Vue + Vite playground for Moon Mustache.

## What it does

- provides explicit Render, Diagnose, Compare, Conformance, and Generate views
- renders through the repository's own compiled MoonBit engine
- surfaces checked-render diagnostics and missing variables without switching back to the CLI
- compares the current input live with the pinned `mustache.js` reference implementation
- loads the official fixture suite counts, pinned commit, and hashes from `third_party/mustache-spec/MANIFEST.json`
- generates a five-file MoonBit starter through the real `TemplateBundle` API
- bundles current test and coverage values from `docs/METRICS_SNAPSHOT.json`
- offers a Chinese-first entry with an English switch

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

- the playground is a product-facing compatibility lab, not a separate JavaScript renderer
- file-backed rendering is still handled by the main CLI
- Render, Diagnose, and Generate use the MoonBit build output; `mustache.js` is isolated to the labeled Compare reference
- generated starter artifacts remain in memory for safe review; the browser does not write to the user's filesystem
