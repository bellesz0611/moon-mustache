///|
fn deployment_manifest_json() -> String {
  let manifest =
    #|{
    #|  "name": "ops-rollout-kit",
    #|  "context": {
    #|    "service": {
    #|      "region": "cn-north"
    #|    }
    #|  },
    #|  "partials": {
    #|    "env_block": "LOG_LEVEL={{service.log_level}}\nFEATURE_FLAG={{service.feature_flag}}\n",
    #|    "contact_block": "owner={{owner.name}}\nchannel={{owner.channel}}\n"
    #|  },
    #|  "profiles": {
    #|    "staging": {
    #|      "context": {
    #|        "service": {
    #|          "replicas": 2,
    #|          "feature_flag": "staging-preview"
    #|        }
    #|      }
    #|    },
    #|    "production": {
    #|      "context": {
    #|        "service": {
    #|          "replicas": 5,
    #|          "feature_flag": "stable"
    #|        }
    #|      }
    #|    }
    #|  },
    #|  "files": [
    #|    {
    #|      "path": "deploy/{{service.name}}/deployment.env",
    #|      "template": "SERVICE={{service.name}}\nREGION={{service.region}}\nREPLICAS={{service.replicas}}\n{{> env_block}}"
    #|    },
    #|    {
    #|      "path": "deploy/{{service.name}}/owner.txt",
    #|      "template": "{{> contact_block}}"
    #|    },
    #|    {
    #|      "path": "deploy/{{service.name}}/summary.md",
    #|      "template": "# {{service.name}}\n\nprofile={{profile_name}}\nreplicas={{service.replicas}}\nregion={{service.region}}\n"
    #|    }
    #|  ]
    #|}
  manifest
}

///|
fn runtime_context(profile_name : String) -> @src.Value {
  @src.Value::object({
    "profile_name": @src.Value::string(profile_name),
    "service": @src.Value::object({
      "name": @src.Value::string("moon-control-plane"),
      "log_level": @src.Value::string("info"),
    }),
    "owner": @src.Value::object({
      "name": @src.Value::string("platform-team"),
      "channel": @src.Value::string("#moon-ops"),
    }),
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
  let manifest =
    @src.parse_bundle_manifest_json(deployment_manifest_json()).unwrap()
  let validation = @src.validate_bundle_manifest(manifest)
  let result = @src.render_bundle_manifest_checked(
    manifest,
    runtime_context("production"),
    @src.RenderOptions::strict(),
    profile_name="production",
  ).unwrap()
  let plan = @src.build_bundle_plan("ops-rollout-kit", result, validation)

  println(@src.format_validation_report_markdown("ops-rollout-kit", validation))
  println("")
  println(@src.format_bundle_plan_markdown(plan))
  println("")

  for file in result.files {
    print_file(file.path, file.output)
  }
}
