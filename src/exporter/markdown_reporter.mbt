// Markdown Scientific Report Generator

///|
pub fn generate_markdown_report(
  model_name : String,
  total_days : Double,
  final_state : @types.StateVector,
  diag_status : String,
) -> String {
  let buf = StringBuilder::new()
  buf.write_string("# Ocean Biogeochemical Box Model Simulation Report\n\n")
  buf.write_string("- **Model Name**: `" + model_name + "`\n")
  buf.write_string(
    "- **Simulation Duration**: `" + total_days.to_string() + " days`\n",
  )
  buf.write_string("- **Mass Audit**: `" + diag_status + "`\n\n")

  buf.write_string("## Final State Variable Summary\n\n")
  buf.write_string("| Variable ID | Name | Final Concentration | Unit |\n")
  buf.write_string("| :--- | :--- | :--- | :--- |\n")

  for i = 0; i < final_state.vars.length(); i = i + 1 {
    let v = final_state.vars[i]
    buf.write_string(
      "| `" +
      v.id +
      "` | " +
      v.name +
      " | " +
      v.value.to_string() +
      " | " +
      @types.unit_symbol(v.unit) +
      " |\n",
    )
  }

  buf.to_string()
}
