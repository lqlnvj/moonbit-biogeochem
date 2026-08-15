// JSON Serialization Utilities for Model Configs and Trajectories

///|
pub fn export_model_config_json(model : @core.BoxModel) -> String {
  let buf = StringBuilder::new()
  buf.write_string("{\n")
  buf.write_string("  \"name\": \"" + model.config.name + "\",\n")
  buf.write_string("  \"version\": \"" + model.config.version + "\",\n")
  buf.write_string(
    "  \"volume_m3\": " + model.config.box_volume_m3.to_string() + ",\n",
  )
  buf.write_string(
    "  \"depth_m\": " + model.config.box_depth_m.to_string() + ",\n",
  )

  // Variables
  buf.write_string("  \"variables\": [\n")
  let vars = model.current_state.vars
  for i = 0; i < vars.length(); i = i + 1 {
    let v = vars[i]
    buf.write_string(
      "    {\"id\": \"" +
      v.id +
      "\", \"name\": \"" +
      v.name +
      "\", \"value\": " +
      v.value.to_string() +
      "}",
    )
    if i < vars.length() - 1 {
      buf.write_string(",\n")
    } else {
      buf.write_string("\n")
    }
  }
  buf.write_string("  ]\n")
  buf.write_string("}")
  buf.to_string()
}
