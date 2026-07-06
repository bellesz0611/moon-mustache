pub enum Value {
  NullValue
  BoolValue(Bool)
  NumberValue(Double)
  StringValue(String)
  ObjectValue(Map[String, Value])
  ArrayValue(Array[Value])
}

pub fn Value::null() -> Value {
  NullValue
}

pub fn Value::bool(value : Bool) -> Value {
  BoolValue(value)
}

pub fn Value::number(value : Double) -> Value {
  NumberValue(value)
}

pub fn Value::string(value : String) -> Value {
  StringValue(value)
}

pub fn Value::object(entries : Map[String, Value]) -> Value {
  ObjectValue(entries)
}

pub fn Value::empty_object() -> Value {
  ObjectValue({})
}

pub fn Value::array(items : Array[Value]) -> Value {
  ArrayValue(items)
}

fn lookup_single(value : Value, name : String) -> Value? {
  match value {
    ObjectValue(map) => map.get(name)
    _ => None
  }
}

fn lookup_path_in_value(value : Value, name : String) -> Value? {
  if name == "." {
    return Some(value)
  }
  match name.split_once(".") {
    Some((head, tail)) =>
      match lookup_single(value, head.to_owned()) {
        Some(next) => lookup_path_in_value(next, tail.to_owned())
        None => None
      }
    None => lookup_single(value, name)
  }
}

fn lookup_head_in_stack(stack : Array[Value], name : String) -> Value? {
  let mut index = stack.length()
  while index > 0 {
    let candidate = stack[index - 1]
    match lookup_single(candidate, name) {
      Some(value) => return Some(value)
      None => ()
    }
    index = index - 1
  }
  None
}

pub fn lookup_name(stack : Array[Value], name : String) -> Value? {
  if stack.length() == 0 {
    return None
  }
  let current = stack[stack.length() - 1]
  if name == "." {
    return Some(current)
  }
  match name.split_once(".") {
    Some((head, tail)) =>
      match lookup_head_in_stack(stack, head.to_owned()) {
        Some(value) => lookup_path_in_value(value, tail.to_owned())
        None => None
      }
    None => lookup_head_in_stack(stack, name)
  }
}

pub fn push_context(stack : Array[Value], value : Value) -> Array[Value] {
  let next = Array::new(capacity=stack.length() + 1)
  for item in stack {
    next.push(item)
  }
  next.push(value)
  next
}

pub fn is_truthy(value : Value) -> Bool {
  match value {
    NullValue => false
    BoolValue(v) => v
    ArrayValue(items) => items.length() > 0
    _ => true
  }
}

pub fn value_to_string(value : Value) -> String {
  match value {
    NullValue => ""
    BoolValue(v) => if v { "true" } else { "false" }
    NumberValue(v) => v.to_string()
    StringValue(v) => v
    ObjectValue(_) => "[object]"
    ArrayValue(_) => "[array]"
  }
}
