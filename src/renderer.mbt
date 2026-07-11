///|
pub let default_partial_depth_limit = 32

///|
pub struct RenderResult {
  output : String
  errors : Array[String]
  missing_variables : Array[String]
}

///|
pub struct PreparedPartials {
  templates : Map[String, String]
  compiled : Map[String, ParseResult]
}

///|
pub struct PreparedTemplate {
  nodes : Array[Node]
  errors : Array[String]
  partials : PreparedPartials
}

///|
priv struct RenderBudget {
  steps : Array[Int]
  section_iterations : Array[Int]
  output_chars : Array[Int]
  stopped : Array[Bool]
  reported : Map[String, Bool]
}

///|
fn RenderBudget::new() -> RenderBudget {
  {
    steps: [0],
    section_iterations: [0],
    output_chars: [0],
    stopped: [false],
    reported: {},
  }
}

///|
fn budget_is_stopped(budget : RenderBudget) -> Bool {
  budget.stopped[0]
}

///|
fn stop_with_resource_error(
  budget : RenderBudget,
  errors : Array[String],
  code : String,
  message : String,
) -> Unit {
  if !budget.reported.get_or_default(code, false) {
    budget.reported[code] = true
    errors.push(code + ": " + message)
  }
  budget.stopped[0] = true
}

///|
fn consume_render_step(
  budget : RenderBudget,
  options : RenderOptions,
  errors : Array[String],
) -> Bool {
  if budget_is_stopped(budget) {
    return false
  }
  budget.steps[0] = budget.steps[0] + 1
  if budget.steps[0] > options.max_render_steps {
    stop_with_resource_error(
      budget,
      errors,
      "MST-LIMIT-003",
      "maximum render steps exceeded (limit " +
      options.max_render_steps.to_string() +
      ")",
    )
    return false
  }
  true
}

///|
fn consume_section_iteration(
  budget : RenderBudget,
  options : RenderOptions,
  errors : Array[String],
) -> Bool {
  if budget_is_stopped(budget) {
    return false
  }
  budget.section_iterations[0] = budget.section_iterations[0] + 1
  if budget.section_iterations[0] > options.max_section_iterations {
    stop_with_resource_error(
      budget,
      errors,
      "MST-LIMIT-002",
      "maximum section iterations exceeded (limit " +
      options.max_section_iterations.to_string() +
      ")",
    )
    return false
  }
  true
}

///|
fn write_render_output(
  output : StringBuilder,
  text : String,
  budget : RenderBudget,
  options : RenderOptions,
  errors : Array[String],
) -> Unit {
  if text == "" || budget_is_stopped(budget) {
    return
  }
  let remaining = options.max_output_chars - budget.output_chars[0]
  if remaining <= 0 {
    stop_with_resource_error(
      budget,
      errors,
      "MST-LIMIT-001",
      "maximum output length exceeded (limit " +
      options.max_output_chars.to_string() +
      ")",
    )
    return
  }
  if text.length() <= remaining {
    output.write_string(text)
    budget.output_chars[0] = budget.output_chars[0] + text.length()
    return
  }
  let mut written = 0
  for char in text {
    if written >= remaining {
      break
    }
    output.write_char(char)
    written = written + 1
  }
  budget.output_chars[0] = budget.output_chars[0] + written
  stop_with_resource_error(
    budget,
    errors,
    "MST-LIMIT-001",
    "maximum output length exceeded (limit " +
    options.max_output_chars.to_string() +
    ")",
  )
}

///|
pub fn PreparedPartials::new(
  partials : Map[String, String],
) -> PreparedPartials {
  let compiled : Map[String, ParseResult] = {}
  for name, template in partials {
    compiled[name] = parse_template(template)
  }
  { templates: partials, compiled }
}

///|
pub fn PreparedTemplate::new(
  template : String,
  partials : Map[String, String],
) -> PreparedTemplate {
  let parsed = parse_template(template)
  {
    nodes: parsed.nodes,
    errors: parsed.errors,
    partials: PreparedPartials::new(partials),
  }
}

///|
pub fn prepare_partials(partials : Map[String, String]) -> PreparedPartials {
  PreparedPartials::new(partials)
}

///|
pub fn prepare_template(
  template : String,
  partials : Map[String, String],
) -> PreparedTemplate {
  PreparedTemplate::new(template, partials)
}

///|
fn render_value(
  output : StringBuilder,
  value : Value,
  escaped : Bool,
  budget : RenderBudget,
  options : RenderOptions,
  errors : Array[String],
) -> Unit {
  let text = value_to_string(value)
  if escaped {
    write_render_output(output, escape_html(text), budget, options, errors)
  } else {
    write_render_output(output, text, budget, options, errors)
  }
}

///|
fn record_missing_variable(
  missing_variables : Array[String],
  missing_variable_set : Map[String, Bool],
  name : String,
) -> Unit {
  if missing_variable_set.get_or_default(name, false) {
    return
  }
  missing_variable_set[name] = true
  missing_variables.push(name)
}

///|
fn indent_partial_template(template : String, indentation : String) -> String {
  if indentation == "" || template == "" {
    return template
  }
  let builder = StringBuilder::new()
  let mut at_line_start = true
  for char in template {
    if at_line_start {
      builder.write_string(indentation)
      at_line_start = false
    }
    builder.write_char(char)
    if char == '\n' {
      at_line_start = true
    }
  }
  builder.to_string()
}

///|
fn indent_template_after_first_line(
  template : String,
  indentation : String,
) -> String {
  if indentation == "" || template == "" {
    return template
  }
  let builder = StringBuilder::new()
  let mut after_newline = false
  for char in template {
    if after_newline {
      builder.write_string(indentation)
      after_newline = false
    }
    builder.write_char(char)
    if char == '\n' {
      after_newline = true
    }
  }
  builder.to_string()
}

///|
fn partial_cache_key(name : String, indentation : String?) -> String {
  match indentation {
    Some(indent) =>
      if indent == "" {
        name
      } else {
        name + "\n--indent--\n" + indent
      }
    None => name
  }
}

///|
fn resolve_partial_parse(
  name : String,
  indentation : String?,
  partials : Map[String, String],
  prepared_partials : Map[String, ParseResult],
  partial_cache : Map[String, ParseResult],
) -> ParseResult? {
  let cache_key = partial_cache_key(name, indentation)
  match partial_cache.get(cache_key) {
    Some(parsed) => Some(parsed)
    None =>
      if cache_key == name {
        match prepared_partials.get(name) {
          Some(parsed) => Some(parsed)
          None =>
            match partials.get(name) {
              Some(template) => {
                let parsed = parse_template(template)
                partial_cache[cache_key] = parsed
                Some(parsed)
              }
              None => None
            }
        }
      } else {
        match partials.get(name) {
          Some(template) => {
            let indented_template = match indentation {
              Some(indent) => indent_partial_template(template, indent)
              None => template
            }
            let parsed = parse_template(indented_template)
            partial_cache[cache_key] = parsed
            Some(parsed)
          }
          None => None
        }
      }
  }
}

///|
fn render_partial(
  output : StringBuilder,
  stack : Array[Value],
  name : String,
  indentation : String?,
  partials : Map[String, String],
  prepared_partials : Map[String, ParseResult],
  partial_cache : Map[String, ParseResult],
  depth : Int,
  options : RenderOptions,
  errors : Array[String],
  missing_variables : Array[String],
  missing_variable_set : Map[String, Bool],
  budget : RenderBudget,
  missing_is_error : Bool,
  block_overrides : Map[String, Array[Node]],
) -> Unit {
  if depth >= options.partial_depth_limit {
    errors.push("partial depth limit exceeded: " + name)
    return
  }
  match
    resolve_partial_parse(
      name, indentation, partials, prepared_partials, partial_cache,
    ) {
    Some(parsed) => {
      for error in parsed.errors {
        errors.push("partial " + name + ": " + error)
      }
      render_nodes_with_stack(
        output,
        parsed.nodes,
        stack,
        partials,
        prepared_partials,
        partial_cache,
        depth + 1,
        options,
        errors,
        missing_variables,
        missing_variable_set,
        budget,
        block_overrides,
      )
    }
    None => if missing_is_error { errors.push("missing partial: " + name) }
  }
}

///|
fn render_dynamic_partial(
  output : StringBuilder,
  stack : Array[Value],
  dynamic_name : String,
  indentation : String?,
  partials : Map[String, String],
  prepared_partials : Map[String, ParseResult],
  partial_cache : Map[String, ParseResult],
  depth : Int,
  options : RenderOptions,
  errors : Array[String],
  missing_variables : Array[String],
  missing_variable_set : Map[String, Bool],
  budget : RenderBudget,
  block_overrides : Map[String, Array[Node]],
) -> Unit {
  match lookup_name(stack, dynamic_name) {
    Some(value) => {
      let resolved_name = value_to_string(value)
      if resolved_name != "" {
        render_partial(
          output, stack, resolved_name, indentation, partials, prepared_partials,
          partial_cache, depth, options, errors, missing_variables, missing_variable_set,
          budget, false, block_overrides,
        )
      }
    }
    None =>
      if options.report_missing_variables {
        record_missing_variable(
          missing_variables, missing_variable_set, dynamic_name,
        )
      }
  }
}

///|
fn node_array_has_newline(nodes : Array[Node]) -> Bool {
  for node in nodes {
    match node {
      Text(text) => if text.contains("\n") { return true }
      Section(children~, ..) | Parent(children~, ..) | Block(children~, ..) =>
        if node_array_has_newline(children) {
          return true
        }
      _ => ()
    }
  }
  false
}

///|
fn collect_node_common_indent(
  nodes : Array[Node],
  current : Array[Int],
) -> Unit {
  for node in nodes {
    match node {
      Text(text) =>
        for view in text.split("\n") {
          let line = view.to_owned()
          if line.trim() != "" {
            let indentation = leading_whitespace_count(line)
            if current[0] < 0 || indentation < current[0] {
              current[0] = indentation
            }
          }
        }
      Section(children~, ..) | Parent(children~, ..) | Block(children~, ..) =>
        collect_node_common_indent(children, current)
      _ => ()
    }
  }
}

///|
fn trim_indentation(indentation : String?, amount : Int) -> String? {
  match indentation {
    Some(value) =>
      if value.length() <= amount {
        Some("")
      } else {
        Some(value[:].view(start_offset=amount).to_owned())
      }
    None => None
  }
}

///|
fn dedent_node_text(text : String, amount : Int) -> String {
  if amount <= 0 {
    return text
  }
  let builder = StringBuilder::new()
  let mut at_line_start = true
  let mut skipped = 0
  for char in text {
    if at_line_start && skipped < amount && (char == ' ' || char == '\t') {
      skipped = skipped + 1
      continue
    }
    builder.write_char(char)
    if char == '\n' {
      at_line_start = true
      skipped = 0
    } else {
      at_line_start = false
    }
  }
  builder.to_string()
}

///|
fn dedent_node_array(nodes : Array[Node], amount : Int) -> Array[Node] {
  let result : Array[Node] = []
  for node in nodes {
    match node {
      Text(text) => result.push(Node::text(dedent_node_text(text, amount)))
      Variable(name~, escaped~) =>
        result.push(
          if escaped {
            Node::variable(name)
          } else {
            Node::raw_variable(name)
          },
        )
      Section(name~, inverted~, children~, raw~, open_delim~, close_delim~) =>
        result.push(
          if inverted {
            Node::inverted_section(
              name,
              dedent_node_array(children, amount),
              raw=dedent_node_text(raw, amount),
              open_delim~,
              close_delim~,
            )
          } else {
            Node::section(
              name,
              dedent_node_array(children, amount),
              raw=dedent_node_text(raw, amount),
              open_delim~,
              close_delim~,
            )
          },
        )
      Partial(name~, indentation~) =>
        result.push(
          Node::partial(name, indentation=trim_indentation(indentation, amount)),
        )
      DynamicPartial(name~, indentation~) =>
        result.push(
          Node::dynamic_partial(
            name,
            indentation=trim_indentation(indentation, amount),
          ),
        )
      Parent(name~, children~, indentation~, standalone~) =>
        result.push(
          Node::parent(
            name,
            dedent_node_array(children, amount),
            indentation=trim_indentation(indentation, amount),
            standalone~,
          ),
        )
      Block(name~, children~, indentation~, standalone~) =>
        result.push(
          Node::block(
            name,
            dedent_node_array(children, amount),
            indentation=trim_indentation(indentation, amount),
            standalone~,
          ),
        )
      Comment(text) => result.push(Node::comment(text))
    }
  }
  result
}

///|
fn strip_override_leading_newline(nodes : Array[Node]) -> Array[Node] {
  if nodes.length() == 0 {
    return nodes
  }
  let result = nodes.copy()
  match result[0] {
    Text(text) =>
      if text.has_prefix("\r\n") {
        result[0] = Node::text(text[:].view(start_offset=2).to_owned())
      } else if text.has_prefix("\n") {
        result[0] = Node::text(text[:].view(start_offset=1).to_owned())
      }
    _ => ()
  }
  result
}

///|
fn normalize_override_nodes(nodes : Array[Node]) -> Array[Node] {
  let stripped = strip_override_leading_newline(nodes)
  if !node_array_has_newline(stripped) {
    return stripped
  }
  let common = [-1]
  collect_node_common_indent(stripped, common)
  if common[0] > 0 {
    dedent_node_array(stripped, common[0])
  } else {
    stripped
  }
}

///|
fn merged_parent_overrides(
  children : Array[Node],
  inherited : Map[String, Array[Node]],
) -> Map[String, Array[Node]] {
  let merged : Map[String, Array[Node]] = {}
  for child in children {
    match child {
      Block(name~, children~, ..) =>
        merged[name] = normalize_override_nodes(children)
      _ => ()
    }
  }
  for name, nodes in inherited {
    merged[name] = nodes
  }
  merged
}

///|
fn render_parent(
  output : StringBuilder,
  stack : Array[Value],
  name : String,
  children : Array[Node],
  indentation : String?,
  standalone : Bool,
  partials : Map[String, String],
  prepared_partials : Map[String, ParseResult],
  partial_cache : Map[String, ParseResult],
  depth : Int,
  options : RenderOptions,
  errors : Array[String],
  missing_variables : Array[String],
  missing_variable_set : Map[String, Bool],
  budget : RenderBudget,
  block_overrides : Map[String, Array[Node]],
) -> Unit {
  if depth >= options.partial_depth_limit {
    errors.push("partial depth limit exceeded: " + name)
    return
  }
  match partials.get(name) {
    Some(template) => {
      let parent_template = match indentation {
        Some(indent) =>
          if standalone {
            indent_partial_template(template, indent)
          } else {
            indent_template_after_first_line(template, indent)
          }
        None => template
      }
      let parsed = parse_template(parent_template)
      for error in parsed.errors {
        errors.push("parent " + name + ": " + error)
      }
      render_nodes_with_stack(
        output,
        parsed.nodes,
        stack,
        partials,
        prepared_partials,
        partial_cache,
        depth + 1,
        options,
        errors,
        missing_variables,
        missing_variable_set,
        budget,
        merged_parent_overrides(children, block_overrides),
      )
    }
    None => ()
  }
}

///|
fn strip_block_leading_newline(text : String) -> String {
  if text.has_prefix("\r\n") {
    text[:].view(start_offset=2).to_owned()
  } else if text.has_prefix("\n") {
    text[:].view(start_offset=1).to_owned()
  } else {
    text
  }
}

///|
fn leading_whitespace_count(text : String) -> Int {
  let mut count = 0
  while count < text.length() {
    let char = text.unsafe_get(count)
    if char == ' ' || char == '\t' {
      count = count + 1
    } else {
      break
    }
  }
  count
}

///|
fn intrinsic_block_indentation(nodes : Array[Node]) -> String {
  for node in nodes {
    match node {
      Text(text) =>
        for view in text.split("\n") {
          let line = view.to_owned()
          if line.trim() != "" {
            let count = leading_whitespace_count(line)
            return line[:].view(end_offset=count).to_owned()
          }
        }
      Section(children~, ..) | Block(children~, ..) => {
        let nested = intrinsic_block_indentation(children)
        if nested != "" {
          return nested
        }
      }
      _ => ()
    }
  }
  ""
}

///|
fn reindent_block_text(
  text : String,
  indentation : String?,
  standalone : Bool,
  default_children : Array[Node],
) -> String {
  let mut normalized = strip_block_leading_newline(text)
  while normalized.has_suffix("\n\n") {
    normalized = normalized[:]
      .view(end_offset=normalized.length() - 1)
      .to_owned()
  }
  let explicit_indent = match indentation {
    Some(value) => value
    None => ""
  }
  let indent = if explicit_indent != "" {
    explicit_indent
  } else {
    intrinsic_block_indentation(default_children)
  }
  if indent == "" || normalized == "" {
    return normalized
  }
  let builder = StringBuilder::new()
  let mut index = 0
  for view in normalized.split("\n") {
    let line = view.to_owned()
    if index > 0 {
      builder.write_string("\n")
    }
    if line != "" && (standalone || index > 0) {
      builder.write_string(indent)
    }
    builder.write_string(line)
    index = index + 1
  }
  builder.to_string()
}

///|
fn render_block(
  output : StringBuilder,
  stack : Array[Value],
  name : String,
  children : Array[Node],
  indentation : String?,
  standalone : Bool,
  partials : Map[String, String],
  prepared_partials : Map[String, ParseResult],
  partial_cache : Map[String, ParseResult],
  depth : Int,
  options : RenderOptions,
  errors : Array[String],
  missing_variables : Array[String],
  missing_variable_set : Map[String, Bool],
  budget : RenderBudget,
  block_overrides : Map[String, Array[Node]],
) -> Unit {
  let selected = match block_overrides.get(name) {
    Some(nodes) => nodes
    None => children
  }
  let temporary_output = StringBuilder::new()
  let previous_output_chars = budget.output_chars[0]
  render_nodes_with_stack(
    temporary_output, selected, stack, partials, prepared_partials, partial_cache,
    depth, options, errors, missing_variables, missing_variable_set, budget, block_overrides,
  )
  budget.output_chars[0] = previous_output_chars
  write_render_output(
    output,
    reindent_block_text(
      temporary_output.to_string(),
      indentation,
      standalone,
      children,
    ),
    budget,
    options,
    errors,
  )
}

///|
fn render_lambda_template(
  output : StringBuilder,
  template : String,
  stack : Array[Value],
  open_delim : String,
  close_delim : String,
  escaped : Bool,
  partials : Map[String, String],
  prepared_partials : Map[String, ParseResult],
  partial_cache : Map[String, ParseResult],
  depth : Int,
  options : RenderOptions,
  errors : Array[String],
  missing_variables : Array[String],
  missing_variable_set : Map[String, Bool],
  budget : RenderBudget,
  block_overrides : Map[String, Array[Node]],
) -> Unit {
  let parsed = parse_tokens(
    scan_with_state(template, { open_delim, close_delim }),
  )
  for error in parsed.errors {
    errors.push("lambda result: " + error)
  }
  let temporary_output = StringBuilder::new()
  let previous_output_chars = budget.output_chars[0]
  render_nodes_with_stack(
    temporary_output,
    parsed.nodes,
    stack,
    partials,
    prepared_partials,
    partial_cache,
    depth,
    options,
    errors,
    missing_variables,
    missing_variable_set,
    budget,
    block_overrides,
  )
  budget.output_chars[0] = previous_output_chars
  let rendered = temporary_output.to_string()
  write_render_output(
    output,
    if escaped {
      escape_html(rendered)
    } else {
      rendered
    },
    budget,
    options,
    errors,
  )
}

///|
fn render_section(
  output : StringBuilder,
  stack : Array[Value],
  name : String,
  inverted : Bool,
  children : Array[Node],
  raw : String,
  open_delim : String,
  close_delim : String,
  partials : Map[String, String],
  prepared_partials : Map[String, ParseResult],
  partial_cache : Map[String, ParseResult],
  depth : Int,
  options : RenderOptions,
  errors : Array[String],
  missing_variables : Array[String],
  missing_variable_set : Map[String, Bool],
  budget : RenderBudget,
  block_overrides : Map[String, Array[Node]],
) -> Unit {
  match lookup_name(stack, name) {
    None =>
      if inverted {
        if consume_section_iteration(budget, options, errors) {
          render_nodes_with_stack(
            output, children, stack, partials, prepared_partials, partial_cache,
            depth, options, errors, missing_variables, missing_variable_set, budget,
            block_overrides,
          )
        }
      }
    Some(value) =>
      if inverted {
        if !is_truthy(value) {
          if consume_section_iteration(budget, options, errors) {
            render_nodes_with_stack(
              output, children, stack, partials, prepared_partials, partial_cache,
              depth, options, errors, missing_variables, missing_variable_set, budget,
              block_overrides,
            )
          }
        }
      } else {
        match value {
          SectionLambda(callback) =>
            render_lambda_template(
              output,
              callback(raw),
              stack,
              open_delim,
              close_delim,
              false,
              partials,
              prepared_partials,
              partial_cache,
              depth,
              options,
              errors,
              missing_variables,
              missing_variable_set,
              budget,
              block_overrides,
            )
          ArrayValue(items) =>
            if items.length() > 0 {
              let next_stack = push_context(stack, items[0])
              if consume_section_iteration(budget, options, errors) {
                render_nodes_with_stack(
                  output, children, next_stack, partials, prepared_partials, partial_cache,
                  depth, options, errors, missing_variables, missing_variable_set,
                  budget, block_overrides,
                )
              }
              let mut index = 1
              while index < items.length() && !budget_is_stopped(budget) {
                next_stack[next_stack.length() - 1] = items[index]
                if consume_section_iteration(budget, options, errors) {
                  render_nodes_with_stack(
                    output, children, next_stack, partials, prepared_partials, partial_cache,
                    depth, options, errors, missing_variables, missing_variable_set,
                    budget, block_overrides,
                  )
                }
                index = index + 1
              }
            }
          _ =>
            if is_truthy(value) {
              let next_stack = push_context(stack, value)
              if consume_section_iteration(budget, options, errors) {
                render_nodes_with_stack(
                  output, children, next_stack, partials, prepared_partials, partial_cache,
                  depth, options, errors, missing_variables, missing_variable_set,
                  budget, block_overrides,
                )
              }
            }
        }
      }
  }
}

///|
fn render_nodes_with_stack(
  output : StringBuilder,
  nodes : Array[Node],
  stack : Array[Value],
  partials : Map[String, String],
  prepared_partials : Map[String, ParseResult],
  partial_cache : Map[String, ParseResult],
  depth : Int,
  options : RenderOptions,
  errors : Array[String],
  missing_variables : Array[String],
  missing_variable_set : Map[String, Bool],
  budget : RenderBudget,
  block_overrides : Map[String, Array[Node]],
) -> Unit {
  for node in nodes {
    if !consume_render_step(budget, options, errors) {
      break
    }
    match node {
      Text(text) => write_render_output(output, text, budget, options, errors)
      Variable(name~, escaped~) =>
        match lookup_name(stack, name) {
          Some(InterpolationLambda(callback)) =>
            render_lambda_template(
              output,
              callback(),
              stack,
              "{{",
              "}}",
              escaped,
              partials,
              prepared_partials,
              partial_cache,
              depth,
              options,
              errors,
              missing_variables,
              missing_variable_set,
              budget,
              block_overrides,
            )
          Some(value) =>
            render_value(output, value, escaped, budget, options, errors)
          None =>
            if options.report_missing_variables {
              record_missing_variable(
                missing_variables, missing_variable_set, name,
              )
            }
        }
      Section(name~, inverted~, children~, raw~, open_delim~, close_delim~) =>
        render_section(
          output, stack, name, inverted, children, raw, open_delim, close_delim,
          partials, prepared_partials, partial_cache, depth, options, errors, missing_variables,
          missing_variable_set, budget, block_overrides,
        )
      Comment(_) => ()
      Partial(name~, indentation~) =>
        render_partial(
          output, stack, name, indentation, partials, prepared_partials, partial_cache,
          depth, options, errors, missing_variables, missing_variable_set, budget,
          true, block_overrides,
        )
      DynamicPartial(name~, indentation~) =>
        render_dynamic_partial(
          output, stack, name, indentation, partials, prepared_partials, partial_cache,
          depth, options, errors, missing_variables, missing_variable_set, budget,
          block_overrides,
        )
      Parent(name~, children~, indentation~, standalone~) =>
        render_parent(
          output, stack, name, children, indentation, standalone, partials, prepared_partials,
          partial_cache, depth, options, errors, missing_variables, missing_variable_set,
          budget, block_overrides,
        )
      Block(name~, children~, indentation~, standalone~) =>
        render_block(
          output, stack, name, children, indentation, standalone, partials, prepared_partials,
          partial_cache, depth, options, errors, missing_variables, missing_variable_set,
          budget, block_overrides,
        )
    }
  }
}

///|
pub fn render_nodes(nodes : Array[Node], context : Value) -> String {
  render_nodes_with_partials(nodes, context, {})
}

///|
pub fn render_string(template : String, context : Value) -> String {
  render_string_with_partials(template, context, {})
}

///|
pub fn render_nodes_with_partials(
  nodes : Array[Node],
  context : Value,
  partials : Map[String, String],
) -> String {
  render_nodes_checked_with_options(
    nodes,
    context,
    partials,
    RenderOptions::default(),
  ).output
}

///|
pub fn render_string_with_partials(
  template : String,
  context : Value,
  partials : Map[String, String],
) -> String {
  render_string_with_partials_checked_with_options(
    template,
    context,
    partials,
    RenderOptions::default(),
  ).output
}

///|
pub fn render_nodes_checked(
  nodes : Array[Node],
  context : Value,
  partials : Map[String, String],
) -> RenderResult {
  render_nodes_checked_with_options(
    nodes,
    context,
    partials,
    RenderOptions::default(),
  )
}

///|
pub fn render_nodes_checked_with_options(
  nodes : Array[Node],
  context : Value,
  partials : Map[String, String],
  options : RenderOptions,
) -> RenderResult {
  let partial_cache : Map[String, ParseResult] = {}
  let errors : Array[String] = []
  let missing_variables : Array[String] = []
  let missing_variable_set : Map[String, Bool] = {}
  let output = StringBuilder::new()
  let budget = RenderBudget::new()
  render_nodes_with_stack(
    output,
    nodes,
    [context],
    partials,
    {},
    partial_cache,
    0,
    options,
    errors,
    missing_variables,
    missing_variable_set,
    budget,
    {},
  )
  { output: output.to_string(), errors, missing_variables }
}

///|
pub fn render_prepared_template(
  prepared : PreparedTemplate,
  context : Value,
) -> String {
  render_prepared_template_checked_with_options(
    prepared,
    context,
    RenderOptions::default(),
  ).output
}

///|
pub fn render_prepared_template_checked(
  prepared : PreparedTemplate,
  context : Value,
) -> RenderResult {
  render_prepared_template_checked_with_options(
    prepared,
    context,
    RenderOptions::default(),
  )
}

///|
pub fn render_prepared_template_checked_with_options(
  prepared : PreparedTemplate,
  context : Value,
  options : RenderOptions,
) -> RenderResult {
  let partial_cache : Map[String, ParseResult] = {}
  let errors = prepared.errors.copy()
  let missing_variables : Array[String] = []
  let missing_variable_set : Map[String, Bool] = {}
  let output = StringBuilder::new()
  let budget = RenderBudget::new()
  render_nodes_with_stack(
    output,
    prepared.nodes,
    [context],
    prepared.partials.templates,
    prepared.partials.compiled,
    partial_cache,
    0,
    options,
    errors,
    missing_variables,
    missing_variable_set,
    budget,
    {},
  )
  { output: output.to_string(), errors, missing_variables }
}

///|
pub fn render_string_checked(
  template : String,
  context : Value,
) -> RenderResult {
  render_string_with_partials_checked_with_options(
    template,
    context,
    {},
    RenderOptions::default(),
  )
}

///|
pub fn render_string_with_partials_checked(
  template : String,
  context : Value,
  partials : Map[String, String],
) -> RenderResult {
  render_string_with_partials_checked_with_options(
    template,
    context,
    partials,
    RenderOptions::default(),
  )
}

///|
pub fn render_string_with_partials_checked_with_options(
  template : String,
  context : Value,
  partials : Map[String, String],
  options : RenderOptions,
) -> RenderResult {
  let parsed = parse_template(template)
  let partial_cache : Map[String, ParseResult] = {}
  let errors = parsed.errors.copy()
  let missing_variables : Array[String] = []
  let missing_variable_set : Map[String, Bool] = {}
  let output = StringBuilder::new()
  let budget = RenderBudget::new()
  render_nodes_with_stack(
    output,
    parsed.nodes,
    [context],
    partials,
    {},
    partial_cache,
    0,
    options,
    errors,
    missing_variables,
    missing_variable_set,
    budget,
    {},
  )
  { output: output.to_string(), errors, missing_variables }
}
