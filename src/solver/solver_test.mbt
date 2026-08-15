// Unit tests for numerical solver algorithms

fn create_test_box_model() -> @core.BoxModel {
  let v1 = @types.StateVariable::new("N", "Nutrient", ConcentrationN, 10.0, 0.0, 100.0)
  let state = @types.StateVector::new([v1])
  let params = @types.ParameterMap::from_array([
    @types.ModelParameter::new("decay", "Decay Rate", 0.1, RatePerDay, 0.0, 1.0, "Decay coefficient")
  ])
  let config = @core.BoxModelConfig::new("decay_model", "1.0", 1000.0, 10.0, state, params)
  
  let evaluator = @core.DerivativeEvaluator::new(fn(_t, y, _env, p) {
    let k = p.get("decay").unwrap()
    [ -k * y[0] ]
  })
  
  @core.BoxModel::new(config, evaluator)
}

test "euler integration on decay model" {
  let model = create_test_box_model()
  let env_fn = fn(_t) { @types.EnvironmentForcing::default_surface() }
  let traj = solve_euler(model, 1.0, 0.1, env_fn).unwrap()
  inspect(traj.length() > 5, content="true")
  let series = traj.get_time_series("N").unwrap()
  let last_val = series[series.length() - 1]
  assert_true(last_val < 10.0)
}

test "rk4 integration precision" {
  let model = create_test_box_model()
  let env_fn = fn(_t) { @types.EnvironmentForcing::default_surface() }
  let traj = solve_rk4(model, 1.0, 0.1, env_fn).unwrap()
  let series = traj.get_time_series("N").unwrap()
  let last_val = series[series.length() - 1]
  // Analytical solution at t=1: 10 * exp(-0.1) = 9.04837
  let err = (last_val - 9.04837).abs()
  assert_true(err < 1.0e-3)
}

test "adaptive rk45 integration" {
  let model = create_test_box_model()
  let env_fn = fn(_t) { @types.EnvironmentForcing::default_surface() }
  let cfg = AdaptiveSolverConfig::default()
  let traj = solve_rk45(model, 1.0, 0.1, cfg, env_fn).unwrap()
  assert_true(traj.length() > 2)
}
