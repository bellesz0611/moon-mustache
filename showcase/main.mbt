///|
fn print_block(title : String, content : String) -> Unit {
  println("== " + title + " ==")
  println(content)
  println("")
}

///|
fn showcase_config_generation() -> String {
  let template =
    #|service = "{{service.name}}"
    #|port = {{service.port}}
    #|debug = {{service.debug}}
    #|
    #|[database]
    #|host = "{{database.host}}"
    #|pool = {{database.pool}}
  let json = "{\"service\":{\"name\":\"moon-mustache\",\"port\":8080,\"debug\":true},\"database\":{\"host\":\"127.0.0.1\",\"pool\":12}}"
  @src.render_json(template, json) catch {
    _ => "<config render failed>"
  }
}

///|
fn showcase_email_template() -> String {
  let template =
    #|Subject: Welcome, {{user.name}}
    #|
    #|Hi {{user.name}},
    #|
    #|Your role is {{user.role}}.
    #|{{#features}}
    #|- {{.}}
    #|{{/features}}
    #|
    #|Thanks,
    #|{{> signature}}
  let json = "{\"user\":{\"name\":\"Alice\",\"role\":\"maintainer\"},\"features\":[\"spec tests\",\"partials\",\"CLI\"]}"
  let partials = { "signature": "MoonBit Tooling Team" }
  @src.render_json_with_partials(template, json, partials) catch {
    _ => "<email render failed>"
  }
}

///|
fn showcase_html_fragment() -> String {
  let template =
    #|<ul>
    #|{{#cards}}
    #|  <li><strong>{{title}}</strong>: {{summary}}</li>
    #|{{/cards}}
    #|</ul>
  let json = "{\"cards\":[{\"title\":\"Config generation\",\"summary\":\"render deployment files from JSON data\"},{\"title\":\"Email templating\",\"summary\":\"assemble reusable notification bodies\"},{\"title\":\"Static snippets\",\"summary\":\"emit predictable HTML fragments\"}]}"
  @src.render_json(template, json) catch {
    _ => "<html render failed>"
  }
}

///|
fn showcase_project_summary() -> String {
  let template =
    #|Project: {{project.name}}
    #|Owner: {{project.owner}}
    #|Repository: {{project.repo}}
    #|
    #|Capabilities:
    #|{{#capabilities}}
    #|- {{.}}
    #|{{/capabilities}}
  let json = "{\"project\":{\"name\":\"moon-mustache\",\"owner\":\"MoonBit community\",\"repo\":\"bellesz0611/moon-mustache\"},\"capabilities\":[\"Mustache rendering core\",\"CLI + file mode\",\"spec compatibility report\",\"benchmark + scaffold demos\"]}"
  @src.render_json(template, json) catch {
    _ => "<summary render failed>"
  }
}

///|
fn main {
  print_block("Config Generation", showcase_config_generation())
  print_block("Email Template", showcase_email_template())
  print_block("HTML Fragment", showcase_html_fragment())
  print_block("Project Summary", showcase_project_summary())
}
