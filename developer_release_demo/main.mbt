///|
fn release_manifest_json() -> String {
  let manifest =
    #|{
    #|  "name": "developer-release-pack",
    #|  "partials": {
    #|    "feature_list": "{{#features}}- {{title}}: {{summary}}\n{{/features}}",
    #|    "upgrade_steps": "{{#upgrade_steps}}{{index}}. {{text}}\n{{/upgrade_steps}}"
    #|  },
    #|  "profiles": {
    #|    "stable": {
    #|      "context": {
    #|        "channel": "stable",
    #|        "install_tag": "latest"
    #|      }
    #|    },
    #|    "preview": {
    #|      "context": {
    #|        "channel": "preview",
    #|        "install_tag": "next"
    #|      }
    #|    }
    #|  },
    #|  "files": [
    #|    {
    #|      "path": "release/{{package.slug}}/github-release.md",
    #|      "template": "# {{package.name}} {{package.version}}\n\nChannel: {{channel}}\n\n## Highlights\n{{> feature_list}}"
    #|    },
    #|    {
    #|      "path": "release/{{package.slug}}/install.md",
    #|      "template": "## Install\n\n`moon add {{package.owner}}/{{package.slug}}@{{install_tag}}`\n\n## Upgrade notes\n{{> upgrade_steps}}"
    #|    },
    #|    {
    #|      "path": "release/{{package.slug}}/migration.txt",
    #|      "template": "Package={{package.name}}\nVersion={{package.version}}\nChannel={{channel}}\nBreaking changes={{breaking_changes}}\n"
    #|    }
    #|  ]
    #|}
  manifest
}

///|
fn release_context() -> @src.Value {
  @src.Value::object({
    "package": @src.Value::object({
      "name": @src.Value::string("moon-mustache"),
      "slug": @src.Value::string("moon-mustache"),
      "owner": @src.Value::string("bellesz0611"),
      "version": @src.Value::string("0.1.0"),
    }),
    "breaking_changes": @src.Value::string("none"),
    "features": @src.Value::array([
      @src.Value::object({
        "title": @src.Value::string("Prepared rendering"),
        "summary": @src.Value::string("compile-once / render-many entrypoints"),
      }),
      @src.Value::object({
        "title": @src.Value::string("Bundle reports"),
        "summary": @src.Value::string("validation and plan reporting for CI"),
      }),
      @src.Value::object({
        "title": @src.Value::string("Official fixture parity"),
        "summary": @src.Value::string("136 imported spec fixtures passing"),
      }),
    ]),
    "upgrade_steps": @src.Value::array([
      @src.Value::object({
        "index": @src.Value::number(1.0),
        "text": @src.Value::string("update the dependency version in moon.mod"),
      }),
      @src.Value::object({
        "index": @src.Value::number(2.0),
        "text": @src.Value::string(
          "rerun project formatting, info, check, and test gates",
        ),
      }),
      @src.Value::object({
        "index": @src.Value::number(3.0),
        "text": @src.Value::string(
          "review the benchmark and compatibility reports",
        ),
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
  let manifest = @src.parse_bundle_manifest_json(release_manifest_json()).unwrap()
  let validation = @src.validate_bundle_manifest(manifest)
  let prepared = @src.prepare_bundle_manifest_profile(
    manifest,
    release_context(),
    profile_name="stable",
  ).unwrap()
  let result = @src.render_prepared_bundle_manifest_checked(
    prepared,
    @src.RenderOptions::strict(),
  )
  let plan = @src.build_bundle_plan(
    "developer-release-pack", result, validation,
  )

  println(
    @src.format_validation_report_markdown("developer-release-pack", validation),
  )
  println("")
  println(@src.format_bundle_plan_markdown(plan))
  println("")

  for file in result.files {
    print_file(file.path, file.output)
  }
}
