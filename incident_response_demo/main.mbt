///|
fn incident_manifest_json() -> String {
  let manifest =
    #|{
    #|  "name": "incident-response-kit",
    #|  "partials": {
    #|    "timeline_steps": "{{#steps}}- {{title}}: {{detail}}\n{{/steps}}",
    #|    "contacts": "{{#contacts}}- {{name}} ({{role}}): {{channel}}\n{{/contacts}}"
    #|  },
    #|  "profiles": {
    #|    "degraded": {
    #|      "context": {
    #|        "severity": "SEV-2",
    #|        "customer_message": "We are investigating elevated error rates."
    #|      }
    #|    },
    #|    "critical": {
    #|      "context": {
    #|        "severity": "SEV-1",
    #|        "customer_message": "We are responding to a critical outage and will provide updates every 15 minutes."
    #|      }
    #|    }
    #|  },
    #|  "files": [
    #|    {
    #|      "path": "incident/{{service.slug}}/runbook.md",
    #|      "template": "# {{service.name}} Incident Runbook\n\nSeverity: {{severity}}\nOwner: {{owner}}\n\n## Response checklist\n{{> timeline_steps}}\n\n## Contacts\n{{> contacts}}"
    #|    },
    #|    {
    #|      "path": "incident/{{service.slug}}/status-page.txt",
    #|      "template": "Service: {{service.name}}\nSeverity: {{severity}}\n\n{{customer_message}}\n"
    #|    },
    #|    {
    #|      "path": "incident/{{service.slug}}/escalation.env",
    #|      "template": "OWNER={{owner}}\nSEVERITY={{severity}}\nPRIMARY_CHANNEL={{primary_channel}}\n"
    #|    }
    #|  ]
    #|}
  manifest
}

///|
fn incident_context() -> @src.Value {
  @src.Value::object({
    "service": @src.Value::object({
      "name": @src.Value::string("moon-control-plane"),
      "slug": @src.Value::string("moon-control-plane"),
    }),
    "owner": @src.Value::string("platform-oncall"),
    "primary_channel": @src.Value::string("#incident-war-room"),
    "steps": @src.Value::array([
      @src.Value::object({
        "title": @src.Value::string("Acknowledge alert"),
        "detail": @src.Value::string(
          "confirm impact and page the incident lead",
        ),
      }),
      @src.Value::object({
        "title": @src.Value::string("Stabilize traffic"),
        "detail": @src.Value::string("shift traffic and reduce blast radius"),
      }),
      @src.Value::object({
        "title": @src.Value::string("Prepare public update"),
        "detail": @src.Value::string("draft the next status-page message"),
      }),
    ]),
    "contacts": @src.Value::array([
      @src.Value::object({
        "name": @src.Value::string("Alicia"),
        "role": @src.Value::string("Incident Lead"),
        "channel": @src.Value::string("@alicia"),
      }),
      @src.Value::object({
        "name": @src.Value::string("Kai"),
        "role": @src.Value::string("Comms"),
        "channel": @src.Value::string("@kai"),
      }),
    ]),
  })
}

///|
fn print_file(path : String, output : String) -> Unit {
  println("== " + path + " ==")
  println(output)
  println("")
}

///|
fn main {
  let manifest = @src.parse_bundle_manifest_json(incident_manifest_json()).unwrap()
  let validation = @src.validate_bundle_manifest(manifest)
  let prepared = @src.prepare_bundle_manifest_profile(
    manifest,
    incident_context(),
    profile_name="critical",
  ).unwrap()
  let result = @src.render_prepared_bundle_manifest_checked(
    prepared,
    @src.RenderOptions::strict(),
  )
  let plan = @src.build_bundle_plan("incident-response-kit", result, validation)

  println(
    @src.format_validation_report_markdown("incident-response-kit", validation),
  )
  println("")
  println(@src.format_bundle_plan_markdown(plan))
  println("")

  for file in result.files {
    print_file(file.path, file.output)
  }
}
