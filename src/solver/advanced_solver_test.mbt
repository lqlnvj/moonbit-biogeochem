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
