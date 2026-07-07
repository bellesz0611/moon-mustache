///|
fn copy_object_entries(entries : Map[String, Value]) -> Map[String, Value] {
  let copied : Map[String, Value] = {}
  for key, value in entries {
    copied[key] = value
  }
  copied
}

///|
pub fn parse_loose_value(input : String) -> Value {
  value_from_json_string(input) catch {
    _ => Value::string(input)
  }
}

///|
fn insert_dotted_value(
  entries : Map[String, Value],
  path : String,
  value : Value,
  errors : Array[String],
) -> Unit {
  if path == "" {
    errors.push("empty variable name is not allowed")
    return
  }
  match path.split_once(".") {
    Some((head, tail)) => {
      if head == "" || tail == "" {
        errors.push("invalid dotted variable path: " + path)
        return
      }
      let key = head.to_owned()
      let child_entries : Map[String, Value] = match entries.get(key) {
        Some(ObjectValue(child)) => copy_object_entries(child)
        Some(_) => {
          errors.push("cannot assign nested path under scalar value: " + key)
          return
        }
        None => {}
      }
      insert_dotted_value(child_entries, tail.to_owned(), value, errors)
      entries[key] = Value::object(child_entries)
    }
    None => entries[path] = value
  }
}

///|
pub fn object_from_dotted_entries(
  entries : Array[(String, Value)],
) -> (Value, Array[String]) {
  let mapped : Map[String, Value] = {}
  let errors : Array[String] = []
  for entry in entries {
    insert_dotted_value(mapped, entry.0, entry.1, errors)
  }
  (Value::object(mapped), errors)
}

///|
pub fn object_from_string_entries(
  entries : Array[(String, String)],
) -> (Value, Array[String]) {
  let parsed : Array[(String, Value)] = []
  for entry in entries {
    parsed.push((entry.0, parse_loose_value(entry.1)))
  }
  object_from_dotted_entries(parsed)
}

///|
pub fn merge_values(base : Value, incoming : Value) -> Value {
  match (base, incoming) {
    (ObjectValue(base_entries), ObjectValue(incoming_entries)) => {
      let merged = copy_object_entries(base_entries)
      for key, incoming_value in incoming_entries {
        match merged.get(key) {
          Some(base_value) =>
            merged[key] = merge_values(base_value, incoming_value)
          None => merged[key] = incoming_value
        }
      }
      Value::object(merged)
    }
    (_, incoming_value) => incoming_value
  }
}
