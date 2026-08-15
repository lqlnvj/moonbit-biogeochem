// Unit tests for Sobol sensitivity and Monte Carlo simulation

///|
fn npzd_test_factory(p_map : @types.ParameterMap) -> @core.BoxModel {
  let v_n = @types.StateVariable::new(
    "N",
    "Nutrient",
    ConcentrationN,
    10.0,
    0.0,
    100.0,
  )
  let v_p = @types.StateVariable::new(
    "P",
    "Phytoplankton",
    ConcentrationN,
    0.5,
    0.0,
    50.0,
  )
  let state = @types.StateVector::new([v_n, v_p])
  let config = @core.BoxModelConfig::new(
    "simple_npzd", "1.0", 1.0e6, 50.0, state, p_map,
  )

  let evaluator = @core.DerivativeEvaluator::new(fn(_t, y, _env, p) {
    let n = y[0]
    let p_conc = y[1]
    let v_max = p.get("v_max").unwrap()
    let dn = -0.1 * v_max * n * p_conc
    let dp = 0.1 * v_max * n * p_conc
    [dn, dp]
  })

  @core.BoxModel::new(config, evaluator)
}

///|
test "sobol global sensitivity calculation" {
  let p_base = @types.ParameterMap::from_array([
    @types.ModelParameter::new(
      "v_max",
      "Max Growth",
      1.5,
      RatePerDay,
      0.5,
      3.0,
      "Growth rate",
    ),
  ])
  let sobol = compute_sobol_indices(
    npzd_test_factory, p_base, "v_max", "P", 5, 2.0,
  ).unwrap()
  assert_true(sobol.first_order_index > 0.0)
}

///|
test "monte carlo simulation analysis" {
  let p_base = @types.ParameterMap::from_array([
    @types.ModelParameter::new(
      "v_max",
      "Max Growth",
      1.5,
      RatePerDay,
      0.5,
      3.0,
      "Growth rate",
    ),
  ])
  let mc = run_monte_carlo_simulation(
    npzd_test_factory, p_base, "v_max", 0.1, "P", 5, 2.0,
  ).unwrap()
  assert_true(mc.mean_val > 0.0)
}
