// Monte Carlo Uncertainty Quantification Engine

///|
pub(all) struct MonteCarloSummary {
  mean_val : Double
  std_dev : Double
  percentile_5 : Double
  percentile_95 : Double
} derive(Debug)

///|
pub fn run_monte_carlo_simulation(
  model_factory : (@types.ParameterMap) -> @core.BoxModel,
  base_params : @types.ParameterMap,
  target_param_id : String,
  param_uncertainty_sd : Double,
  target_var : String,
  num_trials : Int,
  t_end : Double,
) -> Result[MonteCarloSummary, String] {
  let p_base = match base_params.get(target_param_id) {
    Ok(v) => v
    Err(e) => return Err(e)
  }

  let outcomes = Array::new()
  let env_fn = fn(t) { @types.EnvironmentForcing::seasonal_forcing(t, 45.0) }

  for trial = 0; trial < num_trials; trial = trial + 1 {
    // Deterministic pseudo-random variation
    let delta = (trial.to_double() / num_trials.to_double() - 0.5) *
      2.0 *
      param_uncertainty_sd *
      p_base
    let trial_p = p_base + delta
    let p_map = match base_params.set(target_param_id, trial_p) {
      Ok(p) => p
      Err(e) => return Err(e)
    }

    let model = model_factory(p_map)
    let traj = match @solver.solve_rk4(model, t_end, 1.0, env_fn) {
      Ok(tr) => tr
      Err(e) => return Err(e)
    }
    let series = match traj.get_time_series(target_var) {
      Ok(s) => s
      Err(e) => return Err(e)
    }
    let y = series[series.length() - 1]
    outcomes.push(y)
  }

  let mut sum = 0.0
  for i = 0; i < outcomes.length(); i = i + 1 {
    sum = sum + outcomes[i]
  }
  let mean = sum / num_trials.to_double()

  let mut var_sum = 0.0
  for i = 0; i < outcomes.length(); i = i + 1 {
    let diff = outcomes[i] - mean
    var_sum = var_sum + diff * diff
  }
  let sd = (var_sum / num_trials.to_double()).sqrt()

  Ok({
    mean_val: mean,
    std_dev: sd,
    percentile_5: mean - 1.645 * sd,
    percentile_95: mean + 1.645 * sd,
  })
}
