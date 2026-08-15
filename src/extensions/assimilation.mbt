// Observational Data Assimilation & State Nudge Correction

pub(all) struct ObservationPoint {
  time_day : Double
  variable_id : String
  observed_value : Double
  error_variance : Double
} derive(Debug)

pub fn ObservationPoint::new(time : Double, var_id : String, val : Double, var_err : Double) -> ObservationPoint {
  { time_day: time, variable_id: var_id, observed_value: val, error_variance: var_err }
}

pub fn apply_nudge_assimilation(
  current_state : @types.StateVector,
  current_time : Double,
  observations : Array[ObservationPoint],
  nudge_time_scale_days : Double
) -> Result[@types.StateVector, String] {
  let mut updated = current_state
  for i = 0; i < observations.length(); i = i + 1 {
    let obs = observations[i]
    if (obs.time_day - current_time).abs() < 0.5 {
      let model_val = match current_state.get(obs.variable_id) {
        Ok(v) => v
        Err(e) => return Err(e)
      }
      let innovation = obs.observed_value - model_val
      let weight = 1.0 / (1.0 + nudge_time_scale_days)
      let corrected_val = model_val + weight * innovation
      updated = match updated.set(obs.variable_id, corrected_val) {
        Ok(s) => s
        Err(e) => return Err(e)
      }
    }
  }
  Ok(updated)
}
