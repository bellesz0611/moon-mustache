# Architecture Notes

## Core pipeline

Moon Mustache is planned around a small pipeline:

1. scan template text into tokens
2. parse tokens into a tree-like intermediate representation
3. resolve values from a context stack
4. render nodes into final output

## Main components

- `token.mbt`: token definitions and token display helpers
- `ast.mbt`: parsed node model
- `scanner.mbt`: low-level tag scanning
- `parser.mbt`: structural parsing of sections and partials
- `context.mbt`: path lookup and stack operations
- `escape.mbt`: HTML escaping helpers
- `renderer.mbt`: final rendering entry points

## Design choices

- Keep the public API small and file-oriented.
- Make parsing and rendering separable for testing.
- Treat spec compatibility as a first-class goal.
- Prefer explicit data structures over hidden runtime magic.

