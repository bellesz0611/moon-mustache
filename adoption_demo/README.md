# Adoption Demo

This package is a second consumer-style example on top of Moon Mustache.

Unlike `downstream_consumer/`, which focuses on release communication bundles, this package demonstrates an operations-oriented rollout kit:

- multi-file environment output
- profile-aware bundle rendering
- validation and generation-plan reporting
- path templating through bundle file definitions

Run it with:

```bash
moon run adoption_demo
```

The goal is to show that Moon Mustache can support more than one downstream scenario and is not tied to a single example domain.
