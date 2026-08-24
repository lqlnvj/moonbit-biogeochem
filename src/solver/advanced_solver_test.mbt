// Unit tests for implicit and trapezoidal solvers

///|
fn create_simple_model() -> @core.BoxModel {
  let v = @types.StateVariable::new(
    "N",
    "Nutrient",
    ConcentrationN,
    10.0,
    0.0,
    100.0,
  )
  let state = @types.StateVector::new([v])
  let params = @types.ParameterMap::from_array([
    @types.ModelParameter::new("k", "Rate", 0.2, RatePerDay, 0.0, 1.0, "Decay"),
  ])
  let config = @core.BoxModelConfig::new(
    "decay", "1.0", 1000.0, 10.0, state, params,
  )
  let evaluator = @core.DerivativeEvaluator::new(fn(_t, y, _env, p) {
    let k = p.get("k").unwrap()
    [-k * y[0]]
  })
  @core.BoxModel::new(config, evaluator)
}

///|
test "implicit euler solver run" {
  let model = create_simple_model()
  let env_fn = fn(_t) { @types.EnvironmentForcing::default_surface() }
  let traj = solve_implicit_euler(model, 2.0, 0.2, env_fn).unwrap()
  assert_true(traj.length() > 5)
}

///|
test "trapezoidal predictor corrector run" {
  let model = create_simple_model()
  let env_fn = fn(_t) { @types.EnvironmentForcing::default_surface() }
  let traj = solve_trapezoidal(model, 2.0, 0.2, env_fn).unwrap()
  assert_true(traj.length() > 5)
}

///|
test "adams bashforth two step solver handles partial final step" {
  let model = create_simple_model()
  let env_fn = fn(_t) { @types.EnvironmentForcing::default_surface() }
  let traj = solve_adams_bashforth_2(model, 1.05, 0.2, env_fn).unwrap()
  let timestamps = traj.get_timestamps()
  let values = traj.get_time_series("N").unwrap()
  assert_true(timestamps.length() > 5)
  assert_true((timestamps[timestamps.length() - 1] - 1.05).abs() < 1.0e-9)
  assert_true(values[values.length() - 1] >= 0.0)
}

///|
test "adams bashforth three step solver bootstraps and stays nonnegative" {
  let model = create_simple_model()
  let env_fn = fn(_t) { @types.EnvironmentForcing::default_surface() }
  let traj = solve_adams_bashforth_3(model, 0.95, 0.2, env_fn).unwrap()
  let timestamps = traj.get_timestamps()
  let values = traj.get_time_series("N").unwrap()
  assert_true(timestamps.length() > 4)
  assert_true((timestamps[timestamps.length() - 1] - 0.95).abs() < 1.0e-9)
  assert_true(values[values.length() - 1] >= 0.0)
}
