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

///|
test "npzd diagnostics labels sinking as open-system export" {
  let model = @models.create_npzd_model(15.0, 0.5, 0.1, 0.2)
  let env_fn = fn(t) { @types.EnvironmentForcing::seasonal_forcing(t, 45.0) }
  let traj = @solver.solve_rk4(model, 30.0, 0.5, env_fn).unwrap()
  let diag = diagnose_npzd_trajectory(traj).unwrap()
  inspect(diag.mass_conservation_status, content="OPEN_SYSTEM_EXPORT")
}

///|
test "carbon pump metrics handle reference and export edge cases" {
  assert_eq(compute_martin_curve_attenuation(12.0, 100.0, 50.0, 0.8), 12.0)
  assert_eq(compute_martin_curve_attenuation(12.0, 0.0, 1000.0, 0.8), 12.0)
  let deep = compute_martin_curve_attenuation(12.0, 100.0, 1000.0, 0.8)
  assert_true(deep > 0.0 && deep < 12.0)

  let metrics = analyze_biological_carbon_pump(100.0, 10.0, 0.8)
  assert_eq(metrics.surface_primary_production, 100.0)
  assert_eq(metrics.export_flux_100m, 10.0)
  assert_eq(metrics.export_ratio_pe, 0.1)
  assert_true(metrics.deep_flux_1000m > 0.0)
  assert_true(metrics.transfer_efficiency < 1.0)

  let empty = analyze_biological_carbon_pump(0.0, 0.0, 0.8)
  assert_eq(empty.export_ratio_pe, 0.0)
  assert_eq(empty.transfer_efficiency, 0.0)
}
