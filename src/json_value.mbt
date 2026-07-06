pub fn value_from_json(json : Json) -> Value {
  match json {
    Null => Value::null()
    True => Value::bool(true)
    False => Value::bool(false)
    Number(value, ..) => Value::number(value)
    String(value) => Value::string(value)
    Array(items) => Value::array(items.map(item => value_from_json(item)))
    Object(entries) => {
      let mapped : Map[String, Value] = {}
      for key, value in entries {
        mapped[key] = value_from_json(value)
      }
      Value::object(mapped)
    }
  }
}

pub fn value_from_json_string(input : String) -> Value raise @json.ParseError {
  value_from_json(@json.parse(input))
}
