// Unit tests for src/analysis module

///|
fn sample_npzd_factory(p_map : @types.ParameterMap) -> @core.BoxModel {
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
  let v_z = @types.StateVariable::new(
    "Z",
    "Zooplankton",
    ConcentrationN,
    0.1,
    0.0,
    50.0,
  )
  let v_d = @types.StateVariable::new(
    "D",
    "Detritus",
    ConcentrationN,
    0.1,
    0.0,
    100.0,
  )
  let state = @types.StateVector::new([v_n, v_p, v_z, v_d])
  let config = @core.BoxModelConfig::new(
    "sample_npzd", "1.0", 1.0e6, 50.0, state, p_map,
  )

  let evaluator = @core.DerivativeEvaluator::new(fn(_t, y, _env, p) {
    let n = y[0]
    let p_conc = y[1]
    let z = y[2]
    let d = y[3]
    let v_max = p.get("v_max").unwrap()
    let dn = -0.1 * v_max * n * p_conc + 0.05 * d
    let dp = 0.1 * v_max * n * p_conc - 0.05 * p_conc * z
    let dz = 0.05 * p_conc * z - 0.02 * z * z
    let dd = 0.02 * z * z - 0.05 * d
    [dn, dp, dz, dd]
  })

  @core.BoxModel::new(config, evaluator)
}

///|
test "parameter grid sweep run" {
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
  let p_range = ParameterRange::new("v_max", 1.0, 2.0, 3)
  let sweep_res = run_1d_parameter_sweep(
    sample_npzd_factory, p_base, p_range, 5.0, 1.0, "P",
  ).unwrap()
  inspect(sweep_res.length(), content="3")
}

///|
test "local sensitivity computation" {
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
  let sens = compute_local_sensitivity(
    sample_npzd_factory, p_base, "v_max", "P", 0.05, 5.0,
  ).unwrap()
  assert_true(sens.param_id == "v_max")
}

///|
test "npzd trajectory diagnostics" {
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
  let model = sample_npzd_factory(p_base)
  let env_fn = fn(_t) { @types.EnvironmentForcing::default_surface() }
  let traj = @solver.solve_rk4(model, 5.0, 1.0, env_fn).unwrap()
  let diag = diagnose_npzd_trajectory(traj).unwrap()
  inspect(diag.mass_conservation_status, content="CONSERVED")
}
