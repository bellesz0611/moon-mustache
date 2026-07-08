# Companion Repo Blueprint

This directory is a blueprint for how an independent repository could consume Moon Mustache as a package dependency.

It is intentionally structured like a separate project rather than an internal demo-only package.

## What it represents

- a small MoonBit tool depending on `bellesz0611/moon-mustache`
- a dedicated `README.md`
- its own `moon.mod`
- a tiny `src/main.mbt` entrypoint
- a realistic use case: release note and announcement generation

## Why this exists

The main repository already contains several consumer-style demos, but this blueprint goes one step further by showing what a split-out repository shape could look like.

That makes it easier to:

- create a real follow-up repository later
- demonstrate adoption readiness to reviewers
- reduce the gap between internal demos and external consumer projects

## If you want to split this into a real repository later

1. Copy the files in this directory into a new folder outside the current repository.
2. Keep the dependency on `bellesz0611/moon-mustache`.
3. Replace the placeholder repository URL and project metadata.
4. Add your own CI workflow and example data files.
