///|
pub enum TemplateReferenceKind {
  VariableReference
  UnescapedVariableReference
  SectionReference
  InvertedSectionReference
  PartialReference
}

///|
pub struct TemplateReference {
  kind : TemplateReferenceKind
  name : String
}

///|
pub struct TemplateScanResult {
  data_names : Array[String]
  partial_names : Array[String]
  references : Array[TemplateReference]
  uses_current_context : Bool
  uses_dotted_names : Bool
  delimiter_change_count : Int
  parse_errors : Array[String]
}

///|
fn push_unique_name(
  target : Array[String],
  seen : Map[String, Bool],
  name : String,
) -> Unit {
  if seen.get_or_default(name, false) {
    return
  }
  seen[name] = true
  target.push(name)
}

///|
fn record_reference(
  data_names : Array[String],
  partial_names : Array[String],
  seen_data_names : Map[String, Bool],
  seen_partial_names : Map[String, Bool],
  references : Array[TemplateReference],
  kind : TemplateReferenceKind,
  name : String,
  current_context_markers : Array[Bool],
  dotted_name_markers : Array[Bool],
) -> Unit {
  references.push({ kind, name })
  if name == "." {
    if current_context_markers.length() == 0 {
      current_context_markers.push(true)
    }
    return
  }
  match kind {
    PartialReference =>
      push_unique_name(partial_names, seen_partial_names, name)
    _ => {
      push_unique_name(data_names, seen_data_names, name)
      if name.contains(".") && dotted_name_markers.length() == 0 {
        dotted_name_markers.push(true)
      }
    }
  }
}

///|
fn scan_nodes(
  nodes : Array[Node],
  data_names : Array[String],
  partial_names : Array[String],
  seen_data_names : Map[String, Bool],
  seen_partial_names : Map[String, Bool],
  references : Array[TemplateReference],
  current_context_markers : Array[Bool],
  dotted_name_markers : Array[Bool],
) -> Unit {
  for node in nodes {
    match node {
      Text(_) | Comment(_) => ()
      Variable(name~, escaped~) =>
        record_reference(
          data_names,
          partial_names,
          seen_data_names,
          seen_partial_names,
          references,
          if escaped {
            VariableReference
          } else {
            UnescapedVariableReference
          },
          name,
          current_context_markers,
          dotted_name_markers,
        )
      Section(name~, inverted~, children~) => {
        record_reference(
          data_names,
          partial_names,
          seen_data_names,
          seen_partial_names,
          references,
          if inverted {
            InvertedSectionReference
          } else {
            SectionReference
          },
          name,
          current_context_markers,
          dotted_name_markers,
        )
        scan_nodes(
          children, data_names, partial_names, seen_data_names, seen_partial_names,
          references, current_context_markers, dotted_name_markers,
        )
      }
      Partial(name~, ..) =>
        record_reference(
          data_names,
          partial_names,
          seen_data_names,
          seen_partial_names,
          references,
          PartialReference,
          name,
          current_context_markers,
          dotted_name_markers,
        )
    }
  }
}

///|
pub fn scan_template_references(template : String) -> TemplateScanResult {
  let parsed = parse_template(template)
  let tokens = scan_template(template)
  let data_names : Array[String] = []
  let partial_names : Array[String] = []
  let seen_data_names : Map[String, Bool] = {}
  let seen_partial_names : Map[String, Bool] = {}
  let references : Array[TemplateReference] = []
  let current_context_markers : Array[Bool] = []
  let dotted_name_markers : Array[Bool] = []
  let mut delimiter_change_count = 0

  scan_nodes(
    parsed.nodes,
    data_names,
    partial_names,
    seen_data_names,
    seen_partial_names,
    references,
    current_context_markers,
    dotted_name_markers,
  )

  for token in tokens {
    match token.kind {
      SetDelimiter => delimiter_change_count = delimiter_change_count + 1
      _ => ()
    }
  }

  {
    data_names,
    partial_names,
    references,
    uses_current_context: current_context_markers.length() > 0,
    uses_dotted_names: dotted_name_markers.length() > 0,
    delimiter_change_count,
    parse_errors: parsed.errors,
  }
}

///|
pub fn scan_template_variables(template : String) -> Array[String] {
  scan_template_references(template).data_names
}

///|
pub fn scan_template_partials(template : String) -> Array[String] {
  scan_template_references(template).partial_names
}
