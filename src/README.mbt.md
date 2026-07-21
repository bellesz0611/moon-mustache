# Moon Mustache executable examples

This page is compiled and checked with the `src` package. The snippets are tests,
so API changes cannot silently leave the documentation behind.

## Render escaped values

`{{name}}` applies Mustache HTML escaping by default.

```mbt check
///|
test "documentation: escaped render" {
  let context = Value::object({ "name": Value::string("<MoonBit>") })
  inspect(render("Hello {{name}}", context), content="Hello &lt;MoonBit&gt;")
}
```

Use triple braces only for content that has already been made safe.

```mbt check
///|
test "documentation: unescaped render" {
  let context = Value::object({ "html": Value::string("<strong>ok</strong>") })
  inspect(
    render("Result: {{{html}}}", context),
    content="Result: <strong>ok</strong>",
  )
}
```

## Prepare once, render more than once

Applications that reuse a template can parse it once and render the prepared
form with different contexts.

```mbt check
///|
test "documentation: prepared template" {
  let prepared = prepare("Release {{version}}", {})
  let first = Value::object({ "version": Value::string("0.1.0") })
  let second = Value::object({ "version": Value::string("0.2.0") })
  inspect(render_prepared(prepared, first), content="Release 0.1.0")
  inspect(render_prepared(prepared, second), content="Release 0.2.0")
}
```

For checked rendering, resource limits, JSON helpers, and multi-file bundles,
continue with the repository [API guide](../docs/API.md).
