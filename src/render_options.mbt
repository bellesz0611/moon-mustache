///|
pub struct RenderOptions {
  partial_depth_limit : Int
  report_missing_variables : Bool
}

///|
pub fn RenderOptions::default() -> RenderOptions {
  {
    partial_depth_limit: default_partial_depth_limit,
    report_missing_variables: false,
  }
}

///|
pub fn RenderOptions::strict() -> RenderOptions {
  {
    partial_depth_limit: default_partial_depth_limit,
    report_missing_variables: true,
  }
}
