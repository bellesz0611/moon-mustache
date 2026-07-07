# Moon Mustache Playground

This directory contains a Vue + Vite playground for Moon Mustache.

## What it does

- edits Mustache templates in the browser
- edits JSON context and partials side by side
- renders through the repository's own MoonBit engine
- surfaces diagnostics and missing variables without switching back to the CLI

## Run locally

```bash
cd playground
npm install
npm run dev
```

This starts:

- a Vite front-end on port `5173`
- a local Node API on port `4177`

The API uses `playground_bridge/` to call the MoonBit renderer and returns structured JSON to the Vue app.

## Build the front-end

```bash
npm run build
```

## Notes

- the playground is intended for local demos and judge-facing presentations
- file-backed rendering is still handled by the main CLI
- the bridge uses the MoonBit build output instead of a third-party Mustache implementation
