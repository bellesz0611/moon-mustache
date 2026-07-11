///|
pub struct LintOptions {
  report_missing_variables : Bool
  detect_partial_cycles : Bool
}

///|
pub fn LintOptions::default() -> LintOptions {
  { report_missing_variables: true, detect_partial_cycles: true }
}

///|
pub struct LintReport {
  diagnostics : Array[Diagnostic]
  data_names : Array[String]
  partial_names : Array[String]
}

///|
fn diagnostic_with_source_name(
  diagnostic : Diagnostic,
  source_name : String,
) -> Diagnostic {
  {
    code: diagnostic.code,
    severity: diagnostic.severity,
    message: diagnostic.message,
    source_name,
    span: diagnostic.span,
    excerpt: diagnostic.excerpt,
  }
}

///|
fn diagnostic_key(diagnostic : Diagnostic) -> String {
  diagnostic.code +
  "|" +
  diagnostic.source_name +
  "|" +
  diagnostic.span.start.to_string() +
  "|" +
  diagnostic.message
}

///|
fn push_unique_diagnostic(
  diagnostics : Array[Diagnostic],
  seen : Map[String, Bool],
  diagnostic : Diagnostic,
) -> Unit {
  let key = diagnostic_key(diagnostic)
  if !seen.get_or_default(key, false) {
    seen[key] = true
    diagnostics.push(diagnostic)
  }
}

///|
fn reference_span(
  source : String,
  name : String,
  partial_only : Bool,
) -> (Int, Int) {
  for token in scan_template(source) {
    if token.lexeme == name {
      let matches = if partial_only {
        match token.kind {
          Partial | ParentStart => true
          _ => false
        }
      } else {
        match token.kind {
          Variable
          | UnescapedVariable
          | SectionStart
          | InvertedSectionStart
          | DynamicPartial => true
          _ => false
        }
      }
      if matches {
        return (token.start, token.end_)
      }
    }
  }
  (0, 0)
}

///|
fn lint_source_partials(
  source : String,
  source_name : String,
  partials : Map[String, String],
  diagnostics : Array[Diagnostic],
  seen : Map[String, Bool],
) -> Unit {
  for name in scan_template_partials(source) {
    if partials.get(name) is None {
      let (start, end_) = reference_span(source, name, true)
      push_unique_diagnostic(
        diagnostics,
        seen,
        make_diagnostic(
          source,
          "MST-LINT-002",
          DiagnosticError,
          "missing partial: " + name,
          start,
          end_,
          source_name~,
        ),
      )
    }
  }
}

///|
fn visit_partial_dependencies(
  name : String,
  partials : Map[String, String],
  states : Map[String, Int],
  diagnostics : Array[Diagnostic],
  seen : Map[String, Bool],
) -> Unit {
  match states.get(name) {
    Some(2) | Some(1) => return
    _ => ()
  }
  states[name] = 1
  match partials.get(name) {
    Some(source) =>
      for dependency in scan_template_partials(source) {
        match partials.get(dependency) {
          None => ()
          Some(_) =>
            if states.get_or_default(dependency, 0) == 1 {
              let (start, end_) = reference_span(source, dependency, true)
              push_unique_diagnostic(
                diagnostics,
                seen,
                make_diagnostic(
                  source,
                  "MST-LINT-003",
                  DiagnosticError,
                  "partial cycle detected: " + name + " -> " + dependency,
                  start,
                  end_,
                  source_name="partial:" + name,
                ),
              )
            } else {
              visit_partial_dependencies(
                dependency, partials, states, diagnostics, seen,
              )
            }
        }
      }
    None => ()
  }
  states[name] = 2
}

///|
fn lint_partial_set(
  partials : Map[String, String],
  options : LintOptions,
  diagnostics : Array[Diagnostic],
  seen : Map[String, Bool],
) -> Unit {
  for name, source in partials {
    let parsed = parse_template(source)
    for diagnostic in parsed.diagnostics {
      push_unique_diagnostic(
        diagnostics,
        seen,
        diagnostic_with_source_name(diagnostic, "partial:" + name),
      )
    }
    lint_source_partials(source, "partial:" + name, partials, diagnostics, seen)
  }
  if options.detect_partial_cycles {
    let states : Map[String, Int] = {}
    for name, _ in partials {
      visit_partial_dependencies(name, partials, states, diagnostics, seen)
    }
  }
}

///|
pub fn lint_template_with_options(
  template : String,
  context : Value,
  partials : Map[String, String],
  options : LintOptions,
  source_name? : String = "<template>",
) -> LintReport {
  let diagnostics : Array[Diagnostic] = []
  let seen : Map[String, Bool] = {}
  let parsed = parse_template(template)
  for diagnostic in parsed.diagnostics {
    push_unique_diagnostic(
      diagnostics,
      seen,
      diagnostic_with_source_name(diagnostic, source_name),
    )
  }
  lint_source_partials(template, source_name, partials, diagnostics, seen)
  lint_partial_set(partials, options, diagnostics, seen)
  if options.report_missing_variables {
    let rendered = render_string_with_partials_checked_with_options(
      template,
      context,
      partials,
      RenderOptions::strict(),
    )
    for name in rendered.missing_variables {
      let mut diagnostic_source = template
      let mut diagnostic_source_name = source_name
      let mut span = reference_span(template, name, false)
      if span == (0, 0) {
        for partial_name, partial_source in partials {
          let candidate = reference_span(partial_source, name, false)
          if candidate != (0, 0) {
            diagnostic_source = partial_source
            diagnostic_source_name = "partial:" + partial_name
            span = candidate
            break
          }
        }
      }
      push_unique_diagnostic(
        diagnostics,
        seen,
        make_diagnostic(
          diagnostic_source,
          "MST-LINT-001",
          DiagnosticError,
          "missing variable: " + name,
          span.0,
          span.1,
          source_name=diagnostic_source_name,
        ),
      )
    }
  }
  let scan = scan_template_references(template)
  {
    diagnostics,
    data_names: scan.data_names,
    partial_names: scan.partial_names,
  }
}

///|
pub fn lint_template(
  template : String,
  context : Value,
  partials : Map[String, String],
) -> LintReport {
  lint_template_with_options(
    template,
    context,
    partials,
    LintOptions::default(),
  )
}

///|
pub fn lint_template_json(
  template : String,
  context_json : String,
  partials : Map[String, String],
  source_name? : String = "<template>",
) -> LintReport {
  let context = parse_json_context(context_json) catch {
    error => {
      let diagnostic = make_diagnostic(
        context_json,
        "MST-LINT-004",
        DiagnosticError,
        "invalid JSON context: " + error.to_string(),
        0,
        context_json.length(),
        source_name="<context-json>",
      )
      return { diagnostics: [diagnostic], data_names: [], partial_names: [] }
    }
  }
  lint_template_with_options(
    template,
    context,
    partials,
    LintOptions::default(),
    source_name~,
  )
}

///|
pub fn lint_template_bundle(
  bundle : TemplateBundle,
  context : Value,
) -> LintReport {
  let diagnostics : Array[Diagnostic] = []
  let data_names : Array[String] = []
  let partial_names : Array[String] = []
  let seen : Map[String, Bool] = {}
  let validation = validate_template_bundle(bundle)
  for issue in validation.issues {
    let severity = match issue.severity {
      Error => DiagnosticError
      Warning => DiagnosticWarning
    }
    push_unique_diagnostic(
      diagnostics,
      seen,
      make_diagnostic(
        "",
        "MST-BUNDLE-" + issue.code,
        severity,
        issue.message,
        0,
        0,
        source_name=issue.target,
      ),
    )
  }
  for file in bundle.files {
    let report = lint_template_with_options(
      file.template,
      context,
      bundle.partials,
      LintOptions::default(),
      source_name=file.path,
    )
    for diagnostic in report.diagnostics {
      push_unique_diagnostic(diagnostics, seen, diagnostic)
    }
    for name in report.data_names {
      if !data_names.contains(name) {
        data_names.push(name)
      }
    }
    for name in report.partial_names {
      if !partial_names.contains(name) {
        partial_names.push(name)
      }
    }
  }
  { diagnostics, data_names, partial_names }
}

///|
pub fn lint_error_count(report : LintReport) -> Int {
  let mut count = 0
  for diagnostic in report.diagnostics {
    match diagnostic.severity {
      DiagnosticError => count = count + 1
      _ => ()
    }
  }
  count
}

///|
pub fn lint_warning_count(report : LintReport) -> Int {
  let mut count = 0
  for diagnostic in report.diagnostics {
    match diagnostic.severity {
      DiagnosticWarning => count = count + 1
      _ => ()
    }
  }
  count
}

///|
pub fn lint_has_errors(report : LintReport) -> Bool {
  lint_error_count(report) > 0
}

///|
pub fn format_lint_report(report : LintReport) -> String {
  let builder = StringBuilder::new()
  builder.write_string("Moon Mustache lint report\n")
  builder.write_string("errors: ")
  builder.write_string(lint_error_count(report).to_string())
  builder.write_string(", warnings: ")
  builder.write_string(lint_warning_count(report).to_string())
  builder.write_string("\n")
  if report.diagnostics.length() == 0 {
    builder.write_string("status: clean\n")
  } else {
    for diagnostic in report.diagnostics {
      builder.write_string("\n")
      builder.write_string(format_diagnostic(diagnostic))
      builder.write_string("\n")
    }
  }
  builder.to_string()
}
