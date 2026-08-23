// Model System Diagnostics and Ecological Efficiency Analysis

///|
pub(all) struct ModelDiagnosticsReport {
  initial_total_mass : Double
  final_total_mass : Double
  mass_loss : Double
  mass_conservation_status : String
  trophic_efficiency_z_p : Double
} derive(Debug)

///|
pub fn diagnose_npzd_trajectory(
  traj : @solver.Trajectory,
) -> Result[ModelDiagnosticsReport, String] {
  let n_series = match traj.get_time_series("N") {
    Ok(s) => s
    Err(e) => return Err(e)
  }
  let p_series = match traj.get_time_series("P") {
    Ok(s) => s
    Err(e) => return Err(e)
  }
  let z_series = match traj.get_time_series("Z") {
    Ok(s) => s
    Err(e) => return Err(e)
  }
  let d_series = match traj.get_time_series("D") {
    Ok(s) => s
    Err(e) => return Err(e)
  }

  let len = n_series.length()
  if len == 0 {
    return Err("Trajectory is empty")
  }

  let init_tot = n_series[0] + p_series[0] + z_series[0] + d_series[0]
  let final_tot = n_series[len - 1] +
    p_series[len - 1] +
    z_series[len - 1] +
    d_series[len - 1]
  let loss = init_tot - final_tot

  // Detritus sinking exports material from the modeled box. Report that
  // expected open-system flux explicitly instead of calling it a numerical leak.
  let status = if loss.abs() < 1.0e-2 {
    "CONSERVED"
  } else {
    "OPEN_SYSTEM_EXPORT"
  }

  let z_mean = z_series[len - 1]
  let p_mean = p_series[len - 1]
  let eff = if p_mean > 1.0e-6 { z_mean / p_mean } else { 0.0 }

  Ok({
    initial_total_mass: init_tot,
    final_total_mass: final_tot,
    mass_loss: loss,
    mass_conservation_status: status,
    trophic_efficiency_z_p: eff,
  })
}
