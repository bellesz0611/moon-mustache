///|
pub struct BundleProfile {
  context : Value
  partials : Map[String, String]
}

///|
pub struct BundleManifest {
  name : String
  bundle : TemplateBundle
  base_context : Value
  profiles : Map[String, BundleProfile]
}

///|
pub struct ResolvedBundleManifest {
  bundle : TemplateBundle
  context : Value
}

///|
pub struct PreparedResolvedBundleManifest {
  bundle : PreparedTemplateBundle
  context : Value
}

///|
fn json_string_field(
  object : Map[String, Json],
  name : String,
) -> Result[String, String] {
  match object.get(name) {
    Some(String(value)) => Ok(value)
    Some(_) => Err("field `" + name + "` must be a string")
    None => Err("missing string field `" + name + "`")
  }
}

///|
fn optional_json_string_field(
  object : Map[String, Json],
  name : String,
  fallback : String,
) -> Result[String, String] {
  match object.get(name) {
    Some(String(value)) => Ok(value)
    Some(_) => Err("field `" + name + "` must be a string")
    None => Ok(fallback)
  }
}

///|
fn parse_json_value_field(
  object : Map[String, Json],
  name : String,
  fallback : Value,
) -> Result[Value, String] {
  match object.get(name) {
    Some(value) => Ok(value_from_json(value))
    None => Ok(fallback)
  }
}

///|
fn parse_partial_map_json(json : Json) -> Result[Map[String, String], String] {
  let partials : Map[String, String] = @json.from_json(json) catch {
    err => return Err(err.to_string())
  }
  Ok(partials)
}

///|
fn parse_manifest_file_entry(json : Json) -> Result[TemplateFile, String] {
  let object = match json {
    Object(entries) => entries
    _ => return Err("bundle file entry must be an object")
  }
  let path = match json_string_field(object, "path") {
    Ok(value) => value
    Err(message) => return Err(message)
  }
  let template = match json_string_field(object, "template") {
    Ok(value) => value
    Err(message) => return Err(message)
  }
  Ok(TemplateFile::new(path, template))
}

///|
fn parse_manifest_files_field(
  object : Map[String, Json],
) -> Result[Array[TemplateFile], String] {
  match object.get("files") {
    Some(Array(items)) => {
      let files : Array[TemplateFile] = []
      for item in items {
        match parse_manifest_file_entry(item) {
          Ok(file) => files.push(file)
          Err(message) =>
            return Err("invalid bundle manifest file entry: " + message)
        }
      }
      Ok(files)
    }
    Some(_) => Err("field `files` must be an array")
    None => Err("missing array field `files`")
  }
}

///|
fn parse_manifest_partials_field(
  object : Map[String, Json],
) -> Result[Map[String, String], String] {
  match object.get("partials") {
    Some(partials_json) =>
      match parse_partial_map_json(partials_json) {
        Ok(partials) => Ok(partials)
        Err(message) => Err("invalid manifest partials: " + message)
      }
    None => Ok({})
  }
}

///|
fn parse_bundle_profile_entry(json : Json) -> Result[BundleProfile, String] {
  let object = match json {
    Object(entries) => entries
    _ => return Err("bundle profile entry must be an object")
  }
  let context = match
    parse_json_value_field(object, "context", Value::empty_object()) {
    Ok(value) => value
    Err(message) => return Err(message)
  }
  let partials = match object.get("partials") {
    Some(partials_json) =>
      match parse_partial_map_json(partials_json) {
        Ok(value) => value
        Err(message) => return Err("invalid profile partials: " + message)
      }
    None => {}
  }
  Ok({ context, partials })
}

///|
fn parse_manifest_profiles_field(
  object : Map[String, Json],
) -> Result[Map[String, BundleProfile], String] {
  match object.get("profiles") {
    Some(Object(entries)) => {
      let profiles : Map[String, BundleProfile] = {}
      for name, value in entries {
        match parse_bundle_profile_entry(value) {
          Ok(profile) => profiles[name] = profile
          Err(message) =>
            return Err("invalid profile `" + name + "`: " + message)
        }
      }
      Ok(profiles)
    }
    Some(_) => Err("field `profiles` must be an object")
    None => Ok({})
  }
}

///|
pub fn parse_bundle_manifest_json(
  input : String,
) -> Result[BundleManifest, String] {
  let parsed = @json.parse(input) catch {
    err => return Err("invalid bundle manifest JSON: " + err.to_string())
  }
  let object = match parsed {
    Object(entries) => entries
    _ => return Err("bundle manifest must be a JSON object")
  }
  let name = match optional_json_string_field(object, "name", "bundle") {
    Ok(value) => value
    Err(message) => return Err(message)
  }
  let files = match parse_manifest_files_field(object) {
    Ok(value) => value
    Err(message) => return Err(message)
  }
  let partials = match parse_manifest_partials_field(object) {
    Ok(value) => value
    Err(message) => return Err(message)
  }
  let base_context = match
    parse_json_value_field(object, "context", Value::empty_object()) {
    Ok(value) => value
    Err(message) => return Err(message)
  }
  let profiles = match parse_manifest_profiles_field(object) {
    Ok(value) => value
    Err(message) => return Err(message)
  }
  Ok({
    name,
    bundle: TemplateBundle::new(files, partials),
    base_context,
    profiles,
  })
}

///|
fn merge_partial_maps(
  base : Map[String, String],
  incoming : Map[String, String],
) -> Map[String, String] {
  let merged : Map[String, String] = {}
  for name, template in base {
    merged[name] = template
  }
  for name, template in incoming {
    merged[name] = template
  }
  merged
}

///|
pub fn resolve_bundle_manifest_profile(
  manifest : BundleManifest,
  runtime_context : Value,
  profile_name? : String = "",
) -> Result[ResolvedBundleManifest, String] {
  let resolved_context = merge_values(manifest.base_context, runtime_context)
  if profile_name == "" {
    return Ok({ bundle: manifest.bundle, context: resolved_context })
  }
  match manifest.profiles.get(profile_name) {
    Some(profile) => {
      let merged_context = merge_values(resolved_context, profile.context)
      let merged_partials = merge_partial_maps(
        manifest.bundle.partials,
        profile.partials,
      )
      Ok({
        bundle: TemplateBundle::new(manifest.bundle.files, merged_partials),
        context: merged_context,
      })
    }
    None => Err("unknown bundle profile: " + profile_name)
  }
}

///|
pub fn render_bundle_manifest_checked(
  manifest : BundleManifest,
  runtime_context : Value,
  options : RenderOptions,
  profile_name? : String = "",
) -> Result[BundleRenderResult, String] {
  let resolved = match
    resolve_bundle_manifest_profile(manifest, runtime_context, profile_name~) {
    Ok(value) => value
    Err(message) => return Err(message)
  }
  Ok(render_template_bundle_checked(resolved.bundle, resolved.context, options))
}

///|
pub fn prepare_bundle_manifest_profile(
  manifest : BundleManifest,
  runtime_context : Value,
  profile_name? : String = "",
) -> Result[PreparedResolvedBundleManifest, String] {
  let resolved = match
    resolve_bundle_manifest_profile(manifest, runtime_context, profile_name~) {
    Ok(value) => value
    Err(message) => return Err(message)
  }
  Ok({
    bundle: prepare_template_bundle(resolved.bundle),
    context: resolved.context,
  })
}

///|
pub fn render_prepared_bundle_manifest_checked(
  prepared : PreparedResolvedBundleManifest,
  options : RenderOptions,
) -> BundleRenderResult {
  render_prepared_template_bundle_checked(
    prepared.bundle,
    prepared.context,
    options,
  )
}

///|
pub fn render_bundle_manifest_json_checked(
  manifest_json : String,
  context_json : String,
  options : RenderOptions,
) -> Result[BundleRenderResult, String] {
  render_bundle_manifest_json_with_profile_checked(
    manifest_json, context_json, options,
  )
}

///|
pub fn render_bundle_manifest_json_with_profile_checked(
  manifest_json : String,
  context_json : String,
  options : RenderOptions,
  profile_name? : String = "",
) -> Result[BundleRenderResult, String] {
  let manifest = match parse_bundle_manifest_json(manifest_json) {
    Ok(value) => value
    Err(message) => return Err(message)
  }
  let runtime_context = parse_json_context(context_json) catch {
    err => return Err("invalid JSON context: " + err.to_string())
  }
  render_bundle_manifest_checked(
    manifest,
    runtime_context,
    options,
    profile_name~,
  )
}

///|
pub fn prepare_bundle_manifest_json_profile(
  manifest_json : String,
  context_json : String,
  profile_name? : String = "",
) -> Result[PreparedResolvedBundleManifest, String] {
  let manifest = match parse_bundle_manifest_json(manifest_json) {
    Ok(value) => value
    Err(message) => return Err(message)
  }
  let runtime_context = parse_json_context(context_json) catch {
    err => return Err("invalid JSON context: " + err.to_string())
  }
  prepare_bundle_manifest_profile(manifest, runtime_context, profile_name~)
}

///|
pub fn sample_bundle_manifest_json() -> String {
  let sample =
    #|{
    #|  "name": "sample-scaffold",
    #|  "context": {
    #|    "project": {
    #|      "network": "sample-net"
    #|    }
    #|  },
    #|  "partials": {
    #|    "footer": "# Generated by moon-mustache\n",
    #|    "feature_list": "{{#features}}- {{.}}\n{{/features}}"
    #|  },
    #|  "profiles": {
    #|    "dev": {
    #|      "context": {
    #|        "project": { "port": 3000 }
    #|      }
    #|    },
    #|    "prod": {
    #|      "context": {
    #|        "project": { "port": 8080 }
    #|      },
    #|      "partials": {
    #|        "footer": "# Generated for production\n"
    #|      }
    #|    }
    #|  },
    #|  "files": [
    #|    {
    #|      "path": ".env",
    #|      "template": "APP_NAME={{project.name}}\nAPP_PORT={{project.port}}\nNETWORK={{project.network}}\n{{> footer}}"
    #|    },
    #|    {
    #|      "path": "README.generated.md",
    #|      "template": "# {{project.name}}\n\n## Features\n{{> feature_list}}{{> footer}}"
    #|    }
    #|  ]
    #|}
  sample
}
