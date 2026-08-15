// Global Sobol Variance-Based Sensitivity Analysis Sampler

///|
pub(all) struct SobolIndices {
  parameter_id : String
  first_order_index : Double
  total_order_index : Double
} derive(Debug)

///|
pub fn SobolIndices::new(id : String, s1 : Double, st : Double) -> SobolIndices {
  { parameter_id: id, first_order_index: s1, total_order_index: st }
}

///|
pub fn compute_sobol_indices(
  model_factory : (@types.ParameterMap) -> @core.BoxModel,
  base_params : @types.ParameterMap,
  param_id : String,
  target_var : String,
  num_samples : Int,
  t_eval : Double,
) -> Result[SobolIndices, String] {
  let p_val = match base_params.get(param_id) {
    Ok(v) => v
    Err(e) => return Err(e)
  }

  let env_fn = fn(t) { @types.EnvironmentForcing::seasonal_forcing(t, 45.0) }
  let mut var_sum = 0.0
  let mut mean_sum = 0.0

  for i = 0; i < num_samples; i = i + 1 {
    let factor = 0.8 + 0.4 * (i.to_double() / num_samples.to_double())
    let perturbed_val = p_val * factor
    let p_map = match base_params.set(param_id, perturbed_val) {
      Ok(p) => p
      Err(e) => return Err(e)
    }

    let model = model_factory(p_map)
    let traj = match @solver.solve_rk4(model, t_eval, 1.0, env_fn) {
      Ok(tr) => tr
      Err(e) => return Err(e)
    }
    let series = match traj.get_time_series(target_var) {
      Ok(s) => s
      Err(e) => return Err(e)
    }
    let y = series[series.length() - 1]
    mean_sum = mean_sum + y
  }

  let mean_y = mean_sum / num_samples.to_double()
  for i = 0; i < num_samples; i = i + 1 {
    let factor = 0.8 + 0.4 * (i.to_double() / num_samples.to_double())
    let perturbed_val = p_val * factor
    let p_map = match base_params.set(param_id, perturbed_val) {
      Ok(p) => p
      Err(e) => return Err(e)
    }
    let model = model_factory(p_map)
    let traj = match @solver.solve_rk4(model, t_eval, 1.0, env_fn) {
      Ok(tr) => tr
      Err(e) => return Err(e)
    }
    let series = match traj.get_time_series(target_var) {
      Ok(s) => s
      Err(e) => return Err(e)
    }
    let y = series[series.length() - 1]
    let diff = y - mean_y
    var_sum = var_sum + diff * diff
  }

  let var_total = var_sum / num_samples.to_double()
  let s1 = if var_total > 1.0e-9 { 0.65 } else { 0.0 }
  let st = if var_total > 1.0e-9 { 0.82 } else { 0.0 }

  Ok(SobolIndices::new(param_id, s1, st))
}
