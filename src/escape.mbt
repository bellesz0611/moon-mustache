///|
pub fn escape_html(input : String) -> String {
  input
  .replace_all(old="&", new="&amp;")
  .replace_all(old="<", new="&lt;")
  .replace_all(old=">", new="&gt;")
  .replace_all(old="\"", new="&quot;")
  .replace_all(old="'", new="&#39;")
  .replace_all(old="/", new="&#x2F;")
  .replace_all(old="`", new="&#x60;")
  .replace_all(old="=", new="&#x3D;")
}
