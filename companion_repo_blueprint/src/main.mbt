fn main {
  let template =
    #|# {{release.name}}
    #|
    #|{{#items}}
    #|- {{.}}
    #|{{/items}}
  let context = @bellesz0611/moon-mustache/src.Value::object({
    "release": @bellesz0611/moon-mustache/src.Value::object({
      "name": @bellesz0611/moon-mustache/src.Value::string("Moon Release Kit"),
    }),
    "items": @bellesz0611/moon-mustache/src.Value::array([
      @bellesz0611/moon-mustache/src.Value::string("Generated from a standalone consumer blueprint"),
      @bellesz0611/moon-mustache/src.Value::string("Uses Moon Mustache as a package dependency"),
    ]),
  })

  println(@bellesz0611/moon-mustache/src.render(template, context))
}
