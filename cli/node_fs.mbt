#cfg(target="js")
extern "js" fn node_fs_read_text_file_raw(path : String) -> String =
  #|(path) => {
  #|  const fs = require('node:fs')
  #|  try {
  #|    return JSON.stringify([true, fs.readFileSync(path, 'utf8'), null])
  #|  } catch (error) {
  #|    const message = error && error.message ? error.message : String(error)
  #|    return JSON.stringify([false, "", message])
#|  }
#|}

#cfg(target="js")
extern "js" fn node_fs_write_text_file_raw(path : String, content : String) -> String =
  #|(path, content) => {
  #|  const fs = require('node:fs')
  #|  const nodePath = require('node:path')
  #|  try {
  #|    const directory = nodePath.dirname(path)
  #|    if (directory && directory !== '.') {
  #|      fs.mkdirSync(directory, { recursive: true })
  #|    }
  #|    fs.writeFileSync(path, content, 'utf8')
  #|    return JSON.stringify([true, null])
  #|  } catch (error) {
  #|    const message = error && error.message ? error.message : String(error)
#|    return JSON.stringify([false, message])
#|  }
#|}

#cfg(target="js")
fn decode_bridge_read_result(raw : String) -> Result[String, String] {
  let parsed = @json.parse(raw) catch {
    _ => return Err("failed to decode filesystem bridge response")
  }
  let result : (Bool, String, String?) = @json.from_json(parsed) catch {
    _ => return Err("failed to read filesystem bridge payload")
  }
  match result {
    (true, content, _) => Ok(content)
    (false, _, Some(error)) => Err(error)
    _ => Err("file read failed")
  }
}

#cfg(target="js")
fn decode_bridge_write_result(raw : String) -> Result[Unit, String] {
  let parsed = @json.parse(raw) catch {
    _ => return Err("failed to decode filesystem bridge response")
  }
  let result : (Bool, String?) = @json.from_json(parsed) catch {
    _ => return Err("failed to read filesystem bridge payload")
  }
  match result {
    (true, _) => Ok(())
    (false, Some(error)) => Err(error)
    _ => Err("file write failed")
  }
}

#cfg(target="js")
fn read_text_file(path : String) -> Result[String, String] {
  decode_bridge_read_result(node_fs_read_text_file_raw(path))
}

#cfg(target="js")
fn write_text_file(path : String, content : String) -> Result[Unit, String] {
  decode_bridge_write_result(node_fs_write_text_file_raw(path, content))
}

#cfg(not(target="js"))
fn read_text_file(_path : String) -> Result[String, String] {
  Err("file IO is only supported when running the CLI with --target js")
}

#cfg(not(target="js"))
fn write_text_file(_path : String, _content : String) -> Result[Unit, String] {
  Err("file IO is only supported when running the CLI with --target js")
}
