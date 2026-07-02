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

pub fn lookup_name(root : Value, name : String) -> Value? {
  match root {
    ObjectValue(map) => map.get(name)
    _ => None
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
