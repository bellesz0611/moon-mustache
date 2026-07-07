///|
fn is_windows_drive_path(path : String) -> Bool {
  path.length() >= 2 && path[1] == ':'
}

///|
fn normalize_path_separator(char : Char) -> Char {
  if char == '\\' {
    '/'
  } else {
    char
  }
}

///|
fn split_path_segments(path : String) -> Array[String] {
  let segments : Array[String] = []
  let mut current = ""
  for char in path {
    let normalized = normalize_path_separator(char)
    if normalized == '/' {
      segments.push(current)
      current = ""
    } else {
      current = current + normalized.to_string()
    }
  }
  segments.push(current)
  segments
}

///|
fn join_path_segments(segments : Array[String]) -> String {
  if segments.length() == 0 {
    return ""
  }
  let builder = StringBuilder::new()
  let mut index = 0
  while index < segments.length() {
    if index > 0 {
      builder.write_string("/")
    }
    builder.write_string(segments[index])
    index = index + 1
  }
  builder.to_string()
}

///|
pub fn normalize_bundle_path(path : String) -> Result[String, String] {
  if path == "" {
    return Err("path must not be empty")
  }
  if path[0] == '/' || path[0] == '\\' {
    return Err("absolute paths are not allowed: " + path)
  }
  if is_windows_drive_path(path) {
    return Err("drive-qualified paths are not allowed: " + path)
  }
  let normalized_segments : Array[String] = []
  for segment in split_path_segments(path) {
    if segment == "" || segment == "." {
      continue
    }
    if segment == ".." {
      return Err("parent traversal is not allowed: " + path)
    }
    normalized_segments.push(segment)
  }
  if normalized_segments.length() == 0 {
    return Err("path resolves to an empty location: " + path)
  }
  Ok(join_path_segments(normalized_segments))
}

///|
pub fn path_line_count(content : String) -> Int {
  if content == "" {
    return 0
  }
  let mut lines = 1
  for char in content {
    if char == '\n' {
      lines = lines + 1
    }
  }
  lines
}
