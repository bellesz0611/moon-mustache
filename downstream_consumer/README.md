# Downstream Consumer Example

This package is a deliberately separate consumer of `bellesz0611/moon-mustache/src`.

It demonstrates that another MoonBit package can use only the public Moon Mustache API to:

- parse a bundle manifest
- validate output paths and duplicate targets
- resolve a named profile
- render a bundle from runtime data
- generate a validation report and a bundle plan

Run it with:

```bash
moon run downstream_consumer
```

The goal is to provide concrete downstream reuse evidence for competition review, rather than keeping all examples inside the core package itself.
