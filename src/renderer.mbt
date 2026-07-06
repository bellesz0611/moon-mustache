pub let default_partial_depth_limit = 32

pub struct RenderResult {
  output : String
  errors : Array[String]
  missing_variables : Array[String]
}

fn render_value(output : StringBuilder, value : Value, escaped : Bool) -> Unit {
  let text = value_to_string(value)
  if escaped {
    output.write_string(escape_html(text))
  } else {
    output.write_string(text)
  }
}

fn record_missing_variable(missing_variables : Array[String], name : String) -> Unit {
  for existing in missing_variables {
    if existing == name {
      return
    }
  }
  missing_variables.push(name)
}

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

fn render_partial(
  output : StringBuilder,
  stack : Array[Value],
  name : String,
  indentation : String?,
  partials : Map[String, String],
  depth : Int,
  options : RenderOptions,
  errors : Array[String],
  missing_variables : Array[String],
) -> Unit {
  if depth >= options.partial_depth_limit {
    errors.push("partial depth limit exceeded: " + name)
    return
  }
  match partials.get(name) {
    Some(template) => {
      let indented_template =
        match indentation {
          Some(indent) => indent_partial_template(template, indent)
          None => template
        }
      let parsed = parse_template(indented_template)
      for error in parsed.errors {
        errors.push("partial " + name + ": " + error)
      }
      let rendered =
        render_nodes_with_stack(
          parsed.nodes,
          stack,
          partials,
          depth + 1,
          options,
          errors,
          missing_variables,
        )
      output.write_string(
        rendered,
      )
    }
    None => errors.push("missing partial: " + name)
  }
}

fn render_section(
  output : StringBuilder,
  stack : Array[Value],
  name : String,
  inverted : Bool,
  children : Array[Node],
  partials : Map[String, String],
  depth : Int,
  options : RenderOptions,
  errors : Array[String],
  missing_variables : Array[String],
) -> Unit {
  match lookup_name(stack, name) {
    None =>
      if inverted {
        output.write_string(
          render_nodes_with_stack(
            children,
            stack,
            partials,
            depth,
            options,
            errors,
            missing_variables,
          ),
        )
      }
    Some(value) =>
      if inverted {
        if !is_truthy(value) {
          output.write_string(
            render_nodes_with_stack(
              children,
              stack,
              partials,
              depth,
              options,
              errors,
              missing_variables,
            ),
          )
        }
      } else {
        match value {
          ArrayValue(items) => {
            if items.length() > 0 {
              for item in items {
                let next_stack = push_context(stack, item)
                output.write_string(
                  render_nodes_with_stack(
                    children,
                    next_stack,
                    partials,
                    depth,
                    options,
                    errors,
                    missing_variables,
                  ),
                )
              }
            }
          }
          _ =>
            if is_truthy(value) {
              let next_stack = push_context(stack, value)
              output.write_string(
                render_nodes_with_stack(
                  children,
                  next_stack,
                  partials,
                  depth,
                  options,
                  errors,
                  missing_variables,
                ),
              )
            }
        }
      }
  }
}

fn render_nodes_with_stack(
  nodes : Array[Node],
  stack : Array[Value],
  partials : Map[String, String],
  depth : Int,
  options : RenderOptions,
  errors : Array[String],
  missing_variables : Array[String],
) -> String {
  let output = StringBuilder::new()
  for node in nodes {
    match node {
      Text(text) => output.write_string(text)
      Variable(name=name, escaped=escaped) =>
        match lookup_name(stack, name) {
          Some(value) => render_value(output, value, escaped)
          None =>
            if options.report_missing_variables {
              record_missing_variable(missing_variables, name)
            }
        }
      Section(name=name, inverted=inverted, children=children) =>
        render_section(
          output,
          stack,
          name,
          inverted,
          children,
          partials,
          depth,
          options,
          errors,
          missing_variables,
        )
      Comment(_) => ()
      Partial(name=name, indentation=indentation) =>
        render_partial(
          output,
          stack,
          name,
          indentation,
          partials,
          depth,
          options,
          errors,
          missing_variables,
        )
    }
  }
  output.to_string()
}

pub fn render_nodes(nodes : Array[Node], context : Value) -> String {
  render_nodes_with_partials(nodes, context, {})
}

pub fn render_string(template : String, context : Value) -> String {
  render_string_with_partials(template, context, {})
}

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

pub fn render_nodes_checked_with_options(
  nodes : Array[Node],
  context : Value,
  partials : Map[String, String],
  options : RenderOptions,
) -> RenderResult {
  let errors : Array[String] = []
  let missing_variables : Array[String] = []
  let output = render_nodes_with_stack(
    nodes,
    [context],
    partials,
    0,
    options,
    errors,
    missing_variables,
  )
  { output, errors, missing_variables }
}

pub fn render_string_checked(template : String, context : Value) -> RenderResult {
  render_string_with_partials_checked_with_options(
    template,
    context,
    {},
    RenderOptions::default(),
  )
}

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

pub fn render_string_with_partials_checked_with_options(
  template : String,
  context : Value,
  partials : Map[String, String],
  options : RenderOptions,
) -> RenderResult {
  let parsed = parse_template(template)
  let errors = parsed.errors.copy()
  let missing_variables : Array[String] = []
  let output = render_nodes_with_stack(
    parsed.nodes,
    [context],
    partials,
    0,
    options,
    errors,
    missing_variables,
  )
  { output, errors, missing_variables }
}
