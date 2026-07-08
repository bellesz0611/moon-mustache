# Judge Pitch

This page is a concise script for describing Moon Mustache to reviewers or judges.

## 30-second version

Moon Mustache is a reusable Mustache template engine for MoonBit. It is aimed at real engineering tasks such as scaffolding, config generation, content rendering, and multi-file template workflows. The project already includes official `mustache/spec` compatibility evidence, a CLI, bundle validation, a Vue playground, multiple consumer-style demos, CI workflows, and mooncakes.io publication.

## 90-second version

MoonBit still has room for more reusable text-generation infrastructure. Many teams eventually need to turn structured data into text output, but ad hoc string concatenation is hard to scale and hard to validate.

Moon Mustache fills that gap with a smaller, predictable Mustache-based core instead of inventing a new logic-heavy template language. The project is not just a parser demo:

- it has a reusable package API
- it has CLI and file-flow support
- it has official fixture compatibility evidence
- it has bundle validation and plan generation
- it has a playground and a static showcase site
- it has multiple consumer-style demos showing adoption in different workflow domains

So the contribution is both technical and ecological: it gives MoonBit a real reusable template component that other tools can build on.

## Strongest talking points

- official `mustache/spec` evidence instead of self-claimed compatibility
- multiple consumer-style demos instead of one isolated example
- package already published on mooncakes.io
- GitHub + GitLink + CI + docs + playground + site all connected
- project scope is intentionally disciplined, which improves trust and reuse
