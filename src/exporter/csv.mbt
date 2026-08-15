// CSV Export Utilities for Trajectory Time Series

///|
pub fn export_trajectory_csv(traj : @solver.Trajectory) -> String {
  let buf = StringBuilder::new()

  // Header: time, var1, var2, ...
  buf.write_string("time_day")
  for i = 0; i < traj.var_names.length(); i = i + 1 {
    buf.write_string(",")
    buf.write_string(traj.var_names[i])
  }
  buf.write_string("\n")

  // Rows
  for i = 0; i < traj.points.length(); i = i + 1 {
    let pt = traj.points[i]
    buf.write_string(pt.time.to_string())
    for j = 0; j < pt.values.length(); j = j + 1 {
      buf.write_string(",")
      buf.write_string(pt.values[j].to_string())
    }
    buf.write_string("\n")
  }

  buf.to_string()
}
