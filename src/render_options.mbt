///|
pub struct RenderOptions {
  partial_depth_limit : Int
  report_missing_variables : Bool
  max_output_chars : Int
  max_section_iterations : Int
  max_render_steps : Int
}

///|
pub fn RenderOptions::default() -> RenderOptions {
  {
    partial_depth_limit: default_partial_depth_limit,
    report_missing_variables: false,
    max_output_chars: 1_000_000,
    max_section_iterations: 100_000,
    max_render_steps: 1_000_000,
  }
}

///|
pub fn RenderOptions::strict() -> RenderOptions {
  {
    partial_depth_limit: default_partial_depth_limit,
    report_missing_variables: true,
    max_output_chars: 1_000_000,
    max_section_iterations: 100_000,
    max_render_steps: 1_000_000,
  }
}

///|
pub fn RenderOptions::with_resource_limits(
  self : RenderOptions,
  max_output_chars : Int,
  max_section_iterations : Int,
  max_render_steps : Int,
) -> RenderOptions {
  {
    partial_depth_limit: self.partial_depth_limit,
    report_missing_variables: self.report_missing_variables,
    max_output_chars,
    max_section_iterations,
    max_render_steps,
  }
}

///|
pub fn RenderOptions::with_partial_depth_limit(
  self : RenderOptions,
  partial_depth_limit : Int,
) -> RenderOptions {
  {
    partial_depth_limit,
    report_missing_variables: self.report_missing_variables,
    max_output_chars: self.max_output_chars,
    max_section_iterations: self.max_section_iterations,
    max_render_steps: self.max_render_steps,
  }
}
