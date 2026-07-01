pub fn render_nodes(nodes : Array[Node], context : Value) -> String {
  let output = StringBuilder::new()
  for node in nodes {
    match node {
      Text(text) => output.write_string(text)
      Variable(name=name, escaped=escaped) =>
        match lookup_name(context, name) {
          Some(value) =>
            if escaped {
              output.write_string(escape_html(value_to_string(value)))
            } else {
              output.write_string(value_to_string(value))
            }
          None => ()
        }
      Comment(_) => ()
      _ => output.write_string("[render-pending]")
    }
  }
  output.to_string()
}

pub fn render_string(template : String, context : Value) -> String {
  let parsed = parse_template(template)
  render_nodes(parsed.nodes, context)
}

