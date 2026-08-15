// Mermaid Flow Diagram Exporter for Ecological Box Model Topologies

///|
pub fn export_mermaid_diagram(
  model_name : String,
  state_names : Array[String],
) -> String {
  let buf = StringBuilder::new()
  buf.write_string("```mermaid\n")
  buf.write_string("flowchart TD\n")
  buf.write_string("  subgraph " + model_name + " Box Model\n")

  for i = 0; i < state_names.length(); i = i + 1 {
    let name = state_names[i]
    buf.write_string("    " + name + "[" + name + " Compartment]\n")
  }

  // Standard biogeochemical connections if present
  let has_n = state_names.contains("N")
  let has_p = state_names.contains("P")
  let has_z = state_names.contains("Z")
  let has_d = state_names.contains("D")

  if has_n && has_p {
    buf.write_string("    N -->|Primary Production| P\n")
  }
  if has_p && has_z {
    buf.write_string("    P -->|Grazing| Z\n")
  }
  if has_z && has_d {
    buf.write_string("    Z -->|Mortality/Excretion| D\n")
  }
  if has_d && has_n {
    buf.write_string("    D -->|Remineralization| N\n")
  }

  buf.write_string("  end\n")
  buf.write_string("```\n")
  buf.to_string()
}
