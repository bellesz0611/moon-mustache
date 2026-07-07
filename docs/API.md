# API Guide

This document summarizes the current public API surface of Moon Mustache.

The API is intentionally read in two layers:

- core library APIs intended for reuse by downstream MoonBit packages
- companion workflow helpers used for reports, scenario summaries, and competition-facing verification

For versioning expectations, also read `docs/STABILITY.md`.

## Core parsing

- `parse(template)`
  Parses a template into a `ParseResult`.
- `scan_template_variables(template)`
  Collects unique data lookup names referenced by variables and section tags.
- `scan_template_partials(template)`
  Collects unique partial names referenced by the template.
- `scan_template_references(template)`
  Returns a richer `TemplateScanResult` summary, including parse diagnostics and delimiter-change counts.
- `ParseResult.nodes`
  Parsed AST nodes.
- `ParseResult.errors`
  Structural parse diagnostics, such as unterminated sections.

## Core rendering

- `render(template, context)`
  Permissive string rendering API.
- `render_with_partials(template, context, partials)`
  Same as `render`, with in-memory partials.
- `render_checked(template, context)`
  Returns `RenderResult` with output plus diagnostics.
- `render_with_partials_checked(template, context, partials)`
  Checked rendering with partial diagnostics.
- `render_checked_with_options(template, context, options)`
  Checked rendering with configurable diagnostics behavior.
- `render_with_partials_checked_with_options(template, context, partials, options)`
  Same as above, with in-memory partials.

## Render options and diagnostics

- `RenderOptions::default()`
  Default permissive behavior.
- `RenderOptions::strict()`
  Enables missing-variable collection while preserving Mustache rendering semantics.
- `RenderResult.output`
- `RenderResult.errors`
- `RenderResult.missing_variables`

Use checked APIs when embedding Moon Mustache into generators, CI checks, or scaffolding tools that should fail fast on malformed templates or missing data.

## JSON-oriented helpers

- `parse_json_context(json)`
  Converts JSON text into Moon Mustache `Value`.
- `parse_json_partials_checked(json)`
  Parses a JSON object mapping partial names to template strings.
- `render_json(template, context_json)`
  Renders directly from a JSON context string.
- `render_json_with_partials(template, context_json, partials)`
  JSON context plus in-memory partial map.
- `render_json_checked(template, context_json, partials)`
  Checked JSON rendering.
- `render_json_checked_with_options(template, context_json, partials, options)`
  Checked JSON rendering with explicit options.
- `render_json_bundle_checked(template, context_json, partials_json)`
  Checked rendering when both context and partials come from JSON strings.
- `render_json_bundle_checked_with_options(template, context_json, partials_json, options)`
  Same behavior with explicit render options.

## Value model

The library context model is intentionally explicit:

- `Value::null()`
- `Value::bool(...)`
- `Value::number(...)`
- `Value::string(...)`
- `Value::object(...)`
- `Value::array(...)`
- `Value::empty_object()`

## Context construction helpers

- `parse_loose_value(input)`
  Parses a CLI-style scalar or JSON fragment into `Value`.
- `object_from_dotted_entries(entries)`
  Builds nested `Value::object(...)` trees from dotted paths.
- `object_from_string_entries(entries)`
  Same as above, parsing values from strings.
- `merge_values(base, incoming)`
  Recursively merges objects, with incoming scalar values taking precedence.

## Bundle rendering

- `TemplateFile::new(path, template)`
- `TemplateBundle::new(files, partials)`
- `render_template_file_checked(file, context, partials, options)`
- `render_template_bundle_checked(bundle, context, options)`
- `render_template_bundle_json_checked(bundle, context_json, options)`
- `bundle_has_issues(result)`

These APIs are intended for scaffolding tools, configuration generators, and any workflow that needs to render multiple text artifacts from one shared context.

## Manifest-driven bundle rendering

- `parse_bundle_manifest_json(json)`
- `resolve_bundle_manifest_profile(manifest, runtime_context, profile_name)`
- `render_bundle_manifest_checked(manifest, runtime_context, options, profile_name=...)`
- `render_bundle_manifest_json_with_profile_checked(manifest_json, context_json, options, profile_name=...)`
- `sample_bundle_manifest_json()`

These APIs support reusable template projects where one manifest can define files, shared partials, base context, and named profiles such as `dev` or `prod`.

## Validation and planning

- `normalize_bundle_path(path)`
- `validate_template_bundle(bundle)`
- `validate_bundle_manifest(manifest)`
- `validation_error_count(result)`
- `validation_warning_count(result)`
- `validation_has_errors(result)`
- `build_bundle_plan(bundle_name, render_result, validation_result)`

These APIs are useful when a project wants to lint template bundles, block unsafe output paths, or generate release/CI planning artifacts before writing files.

## Report helpers

These helpers are useful, but should currently be treated as faster-evolving than the rendering core.

- `format_spec_report_markdown(results)`
- `format_bundle_result_markdown(bundle_name, result)`
- `format_bundle_result_json(bundle_name, result)`
- `format_validation_report_markdown(bundle_name, result)`
- `format_bundle_plan_markdown(plan)`
- `run_scenario_report()`
- `format_scenario_report_markdown(results)`

## Rendering behavior notes

- Missing variables render as empty strings.
- Missing partials are reported through checked APIs.
- Checked APIs preserve output while also surfacing diagnostics.
- Strict options can additionally report missing variables without changing rendered output semantics.
- Partial recursion is protected by a depth limit.
