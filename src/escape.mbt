///|
pub fn escape_html(input : String) -> String {
  input
  .replace(old="&", new="&amp;")
  .replace(old="<", new="&lt;")
  .replace(old=">", new="&gt;")
  .replace(old="\"", new="&quot;")
  .replace(old="'", new="&#39;")
}
