# Differential Testing

Moon Mustache complements fixture-based testing with a deterministic cross-implementation suite against `mustache.js` 4.2.0.

## Reproduce

```bash
cd playground
npm ci
npm run differential
```

The command compiles `browser_bridge` from MoonBit to an ES module, generates 2,048 cases with seed `20260710`, renders every case with both implementations in one Node.js process, and exits non-zero on the first mismatch group.

## Generated coverage

The corpus varies escaped and unescaped interpolation, booleans, sections, inverted sections, arrays of objects, dotted lookup, missing values, indented partials, delimiter changes, comments, and nested context lookup. Failure output includes the seed, case index, full template, context, partial map, expected output, actual output, and Moon Mustache diagnostics.

The optional dynamic-name, inheritance, and lambda semantics are verified by their upstream `mustache/spec` fixtures rather than by this JSON-generated corpus. JSON cannot represent executable lambda values.

## Defect found

The first differential run found that HTML escaping used single-occurrence string replacement. Repeated angle brackets and ampersands after the first match could remain unescaped, and the extended Mustache escape set was incomplete. The implementation now performs all-occurrence escaping for the complete `mustache.js` entity set, and a focused unit regression test protects the exact failure shape.

## CI policy

The same fixed corpus runs in the playground workflow and before GitHub Pages packaging. Keeping a stable seed makes failures reproducible; changing or adding seeds can broaden coverage without weakening the existing regression baseline.
