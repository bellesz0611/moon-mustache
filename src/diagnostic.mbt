///|
pub enum DiagnosticSeverity {
  DiagnosticInfo
  DiagnosticWarning
  DiagnosticError
}

///|
pub struct SourceSpan {
  start : Int
  end_ : Int
  line : Int
  column : Int
  end_line : Int
  end_column : Int
}

///|
pub struct Diagnostic {
  code : String
  severity : DiagnosticSeverity
  message : String
  source_name : String
  span : SourceSpan
  excerpt : String
}

///|
fn clamp_source_offset(source : String, offset : Int) -> Int {
  if offset < 0 {
    0
  } else if offset > source.length() {
    source.length()
  } else {
    offset
  }
}

///|
fn source_line_column(source : String, offset : Int) -> (Int, Int) {
  let target = clamp_source_offset(source, offset)
  let mut line = 1
  let mut column = 1
  let mut index = 0
  while index < target {
    if source.unsafe_get(index) == '\n' {
      line = line + 1
      column = 1
    } else {
      column = column + 1
    }
    index = index + 1
  }
  (line, column)
}

///|
fn source_line_excerpt(source : String, offset : Int) -> String {
  if source == "" {
    return ""
  }
  let target = clamp_source_offset(source, offset)
  let mut line_start = target
  while line_start > 0 && source.unsafe_get(line_start - 1) != '\n' {
    line_start = line_start - 1
  }
  let mut line_end = target
  while line_end < source.length() && source.unsafe_get(line_end) != '\n' {
    line_end = line_end + 1
  }
  source[:].view(start_offset=line_start, end_offset=line_end).to_owned()
}

///|
pub fn make_diagnostic(
  source : String,
  code : String,
  severity : DiagnosticSeverity,
  message : String,
  start : Int,
  end_ : Int,
  source_name? : String = "<template>",
) -> Diagnostic {
  let safe_start = clamp_source_offset(source, start)
  let safe_end = clamp_source_offset(
    source,
    if end_ < safe_start {
      safe_start
    } else {
      end_
    },
  )
  let (line, column) = source_line_column(source, safe_start)
  let (end_line, end_column) = source_line_column(source, safe_end)
  {
    code,
    severity,
    message,
    source_name,
    span: {
      start: safe_start,
      end_: safe_end,
      line,
      column,
      end_line,
      end_column,
    },
    excerpt: source_line_excerpt(source, safe_start),
  }
}

///|
pub fn make_warning_diagnostic(
  source : String,
  code : String,
  message : String,
  start : Int,
  end_ : Int,
  source_name? : String = "<template>",
) -> Diagnostic {
  make_diagnostic(
    source,
    code,
    DiagnosticWarning,
    message,
    start,
    end_,
    source_name~,
  )
}

///|
pub fn make_info_diagnostic(
  source : String,
  code : String,
  message : String,
  start : Int,
  end_ : Int,
  source_name? : String = "<template>",
) -> Diagnostic {
  make_diagnostic(
    source,
    code,
    DiagnosticInfo,
    message,
    start,
    end_,
    source_name~,
  )
}

///|
pub fn DiagnosticSeverity::label(self : DiagnosticSeverity) -> String {
  match self {
    DiagnosticInfo => "info"
    DiagnosticWarning => "warning"
    DiagnosticError => "error"
  }
}

///|
pub fn format_diagnostic(diagnostic : Diagnostic) -> String {
  let builder = StringBuilder::new()
  builder.write_string(diagnostic.source_name)
  builder.write_string(":")
  builder.write_string(diagnostic.span.line.to_string())
  builder.write_string(":")
  builder.write_string(diagnostic.span.column.to_string())
  builder.write_string(": ")
  builder.write_string(diagnostic.severity.label())
  builder.write_string(" [")
  builder.write_string(diagnostic.code)
  builder.write_string("] ")
  builder.write_string(diagnostic.message)
  if diagnostic.excerpt != "" {
    builder.write_string("\n  ")
    builder.write_string(diagnostic.excerpt)
    builder.write_string("\n  ")
    let mut column = 1
    while column < diagnostic.span.column {
      builder.write_string(" ")
      column = column + 1
    }
    builder.write_string("^")
  }
  builder.to_string()
}
