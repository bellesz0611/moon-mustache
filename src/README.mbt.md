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

## Render sections and arrays

Sections iterate over arrays while keeping each item as the current context.

```mbt check
///|
test "documentation: sections and arrays" {
  let context = Value::object({
    "tools": Value::array([
      Value::object({ "name": Value::string("scanner") }),
      Value::object({ "name": Value::string("renderer") }),
    ]),
  })
  inspect(
    render("{{#tools}}- {{name}}\n{{/tools}}", context),
    content="- scanner\n- renderer\n",
  )
}
```

## Reuse partial templates

Partials are supplied in memory, so callers control exactly which fragments a
template can include.

```mbt check
///|
test "documentation: partial render" {
  let context = Value::object({
    "project": Value::string("Moon Mustache"),
    "status": Value::string("verified"),
  })
  let partials : Map[String, String] = { "badge": "{{project}}: {{status}}" }
  inspect(
    render_with_partials("Build {{> badge}}", context, partials),
    content="Build Moon Mustache: verified",
  )
}
```

## Turn missing data into diagnostics

Strict mode preserves Mustache's empty-string output while also returning the
missing names, in first-seen order, for CI or editor integrations.

```mbt check
///|
test "documentation: strict missing-variable diagnostics" {
  let result = render_checked_with_options(
    "{{name}} is maintained by {{owner}}",
    Value::empty_object(),
    RenderOptions::strict(),
  )
  inspect(result.output, content=" is maintained by ")
  inspect(result.errors.length(), content="0")
  inspect(result.missing_variables.length(), content="2")
  inspect(result.missing_variables[0], content="name")
  inspect(result.missing_variables[1], content="owner")
}
```

## Generate more than one file

Bundle rendering applies one context to multiple path and body templates. It
returns artifacts instead of writing to disk, so the caller can validate or
preview the plan before committing any output.

```mbt check
///|
test "documentation: multi-file generation" {
  let bundle = TemplateBundle::new(
    [
      TemplateFile::new("moon.mod.json", "{\"name\":\"{{name}}\"}"),
      TemplateFile::new("README.md", "# {{name}}\n{{description}}"),
    ],
    {},
  )
  let context = Value::object({
    "name": Value::string("moon-mustache-starter"),
    "description": Value::string("Generated with checked templates."),
  })
  let result = render_template_bundle_checked(
    bundle,
    context,
    RenderOptions::strict(),
  )
  inspect(result.errors.length(), content="0")
  inspect(result.missing_variables.length(), content="0")
  inspect(result.files.length(), content="2")
  inspect(result.files[0].path, content="moon.mod.json")
  inspect(
    result.files[0].output,
    content="{\"name\":\"moon-mustache-starter\"}",
  )
  inspect(result.files[1].path, content="README.md")
}
```

For resource limits, JSON helpers, bundle manifests, and the remaining checked
APIs, continue with the repository [API guide](../docs/API.md).
