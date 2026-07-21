# Cross-Backend Golden Conformance

Moon Mustache runs one deterministic rendering and diagnostics corpus through the MoonBit `wasm`, `wasm-gc`, `js`, and `native` targets. Every target must match both the committed golden output and every other backend byte for byte after line-ending normalization.

The corpus covers HTML escaping, nested Section lookup, Partials, delimiter changes, strict missing-variable reporting, and malformed-template diagnostics. Its executable entrypoint is [`backend_conformance/main.mbt`](../backend_conformance/main.mbt), and the reviewed expectation is [`backend_conformance/golden.txt`](../backend_conformance/golden.txt).

Run the backends that do not require a local C compiler:

```bash
python scripts/test_backend_conformance.py
```

Require all four backends, as Linux CI does:

```bash
python scripts/test_backend_conformance.py \
  --targets wasm,wasm-gc,js,native \
  --require-native \
  --json-output _artifacts/backend-conformance.json
```

The machine-readable report records each target's exit code, duration, normalized SHA-256, golden comparison, and unified diff on failure. Separate per-target unit-test lanes remain useful, but this direct comparison proves that the same observable corpus has the same output across targets.
