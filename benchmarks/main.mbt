fn benchmark_context() -> @src.Value {
  let users : Array[@src.Value] = [
    @src.Value::object({
      "name": @src.Value::string("Alice"),
      "role": @src.Value::string("admin"),
    }),
    @src.Value::object({
      "name": @src.Value::string("Bob"),
      "role": @src.Value::string("developer"),
    }),
    @src.Value::object({
      "name": @src.Value::string("Carol"),
      "role": @src.Value::string("reviewer"),
    }),
  ]
  @src.Value::object({
    "service": @src.Value::string("moon-mustache"),
    "users": @src.Value::array(users),
    "enabled": @src.Value::bool(true),
  })
}

fn bench_plain_render(bencher : @bench.Bench) -> Unit {
  let context = benchmark_context()
  bencher.bench(
    name="plain_render",
    count=10,
    fn() {
      let output = @src.render("Hello {{service}}!", context)
      bencher.keep(output)
    },
  )
}

fn bench_section_render(bencher : @bench.Bench) -> Unit {
  let context = benchmark_context()
  let template = "{{#users}}{{name}}:{{role}};{{/users}}"
  bencher.bench(
    name="section_render",
    count=10,
    fn() {
      let output = @src.render(template, context)
      bencher.keep(output)
    },
  )
}

fn bench_partial_render(bencher : @bench.Bench) -> Unit {
  let context = benchmark_context()
  let partials : Map[String, String] = {
    "user": "[{{name}}:{{role}}]"
  }
  let template = "{{#users}}{{> user}}{{/users}}"
  bencher.bench(
    name="partial_render",
    count=10,
    fn() {
      let output = @src.render_with_partials(template, context, partials)
      bencher.keep(output)
    },
  )
}

fn bench_json_bundle_render(bencher : @bench.Bench) -> Unit {
  let template = "{{#users}}{{> user}}{{/users}}"
  let context_json =
    "{\"users\":[{\"name\":\"Alice\",\"role\":\"admin\"},{\"name\":\"Bob\",\"role\":\"developer\"}]}"
  let partials_json = "{\"user\":\"[{{name}}:{{role}}]\"}"
  bencher.bench(
    name="json_bundle_render",
    count=10,
    fn() {
      let result = @src.render_json_bundle_checked(
        template,
        context_json,
        partials_json,
      )
      bencher.keep(result.output)
    },
  )
}

fn main {
  let bencher = @bench.Bench()
  bench_plain_render(bencher)
  bench_section_render(bencher)
  bench_partial_render(bencher)
  bench_json_bundle_render(bencher)
  println(bencher.dump_summaries())
}
