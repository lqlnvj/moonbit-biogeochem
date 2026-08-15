// Finite Difference Local Sensitivity Analysis Engine

///|
pub(all) struct SensitivityCoefficient {
  param_id : String
  var_id : String
  absolute_sensitivity : Double
  normalized_sensitivity : Double
} derive(Debug)

///|
pub fn compute_local_sensitivity(
  model_factory : (@types.ParameterMap) -> @core.BoxModel,
  base_params : @types.ParameterMap,
  param_id : String,
  target_var : String,
  delta_fraction : Double,
  t_eval : Double,
) -> Result[SensitivityCoefficient, String] {
  let base_p_val = match base_params.get(param_id) {
    Ok(v) => v
    Err(e) => return Err(e)
  }
  let delta_p = if base_p_val.abs() < 1.0e-12 {
    delta_fraction
  } else {
    base_p_val * delta_fraction
  }

  // Nominal run
  let model_base = model_factory(base_params)
  let env_fn = fn(t) { @types.EnvironmentForcing::seasonal_forcing(t, 45.0) }
  let traj_base = match @solver.solve_rk4(model_base, t_eval, 0.5, env_fn) {
    Ok(tr) => tr
    Err(e) => return Err(e)
  }
  let series_base = match traj_base.get_time_series(target_var) {
    Ok(s) => s
    Err(e) => return Err(e)
  }
  let y_base = series_base[series_base.length() - 1]

  // Perturbed run (p + delta_p)
  let params_plus = match base_params.set(param_id, base_p_val + delta_p) {
    Ok(p) => p
    Err(e) => return Err(e)
  }
  let model_plus = model_factory(params_plus)
  let traj_plus = match @solver.solve_rk4(model_plus, t_eval, 0.5, env_fn) {
    Ok(tr) => tr
    Err(e) => return Err(e)
  }
  let series_plus = match traj_plus.get_time_series(target_var) {
    Ok(s) => s
    Err(e) => return Err(e)
  }
  let y_plus = series_plus[series_plus.length() - 1]

  let abs_sens = (y_plus - y_base) / delta_p
  let norm_sens = if y_base.abs() > 1.0e-12 {
    abs_sens * (base_p_val / y_base)
  } else {
    0.0
  }

  Ok({
    param_id,
    var_id: target_var,
    absolute_sensitivity: abs_sens,
    normalized_sensitivity: norm_sens,
  })
}
