# Architecture Notes

## Core pipeline

Moon Mustache is built around a small, explicit pipeline:

1. scan template text into tokens
2. parse tokens into a tree-like intermediate representation
3. resolve values from a context stack
4. render nodes into final output

## Main components

- `token.mbt`: token definitions and token display helpers
- `ast.mbt`: parsed node model
- `scanner.mbt`: low-level tag scanning
- `parser.mbt`: structural parsing of sections and partials
- `diagnostic.mbt`: stable diagnostic codes, source spans, positions, and excerpts
- `lint.mbt`: syntax, data, partial-cycle, JSON, and output-path analysis
- `context.mbt`: path lookup and stack operations
- `json_value.mbt`: JSON-to-template-context adapter
- `escape.mbt`: HTML escaping helpers
- `renderer.mbt`: final rendering entry points
- `bundle*.mbt`: multi-file rendering, manifest parsing, validation, and plan output
- `official_spec_*.mbt`: imported upstream fixture execution and reporting
- `scenario_report.mbt`: workflow-level scenario execution
- `cli_core/`: side-effect-free CLI parsing, diagnostics, report selection, path composition, and output-blocking decisions
- `cli/node_fs.mbt`: Node.js-backed file bridge for CLI file workflows
- `browser_bridge`: exported MoonBit ES module used directly by the Vue playground

## Design choices

- Keep the public API small and easy to embed.
- Make scanning, parsing, and rendering separable for testing.
- Treat spec compatibility as a first-class goal.
- Prefer explicit data structures over hidden runtime magic.
- Use a context stack so sections and `{{.}}` behave predictably.
- Support partial expansion in the renderer instead of baking it into parsing.
- Separate permissive rendering from checked rendering so library users can choose ergonomics or diagnostics.

## Current behavior

当前实现已经支持：

- escaped / unescaped variables
- section and inverted section rendering
- dotted name lookup across context stack layers
- array iteration with current-context rebinding
- partial rendering with depth limit protection
- dynamic partial names, parent templates, block inheritance, and native MoonBit lambdas
- delimiter switching during scanning
- JSON context parsing for CLI and embedding scenarios
- checked rendering results that surface parse and partial diagnostics
- deterministic limits for output size, section iterations, and total render steps
- source-aware structured diagnostics and lint reports with stable error codes
- file-backed CLI rendering flows when running under the `js` target
- standalone-line handling in the scanner for section-like tags
- partial indentation behavior aligned with imported official fixtures
- bundle manifest validation and path normalization checks
- separate downstream package proving public API reuse
- direct browser execution from a MoonBit-compiled ES module

## Near-term architecture work

接下来会继续补强：

- file-oriented adapters on top of the core string API
- scheduled detection of upstream Mustache fixture updates, with deliberate regeneration
- independent third-party adoption and release-over-release performance history
