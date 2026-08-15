// Integration tests for built-in ecosystem models

///|
test "npzd model simulation run" {
  let model = create_npzd_model(15.0, 0.5, 0.1, 0.2)
  let env_fn = fn(t) { @types.EnvironmentForcing::seasonal_forcing(t, 45.0) }
  let traj = @solver.solve_rk4(model, 10.0, 0.5, env_fn).unwrap()
  assert_true(traj.length() > 10)
}

///|
test "oxygen depletion model run" {
  let model = create_oxygen_depletion_model(250.0, 50.0)
  let env_fn = fn(_t) { @types.EnvironmentForcing::default_surface() }
  let traj = @solver.solve_euler(model, 5.0, 0.2, env_fn).unwrap()
  let series = traj.get_time_series("DO").unwrap()
  assert_true(series.length() > 5)
}

///|
test "coupled npzd carbon o2 model adaptive run" {
  let model = create_coupled_carbon_npzd_model(
    12.0, 0.8, 0.2, 0.1, 240.0, 2100.0, 2300.0,
  )
  let env_fn = fn(t) { @types.EnvironmentForcing::seasonal_forcing(t, 30.0) }
  let cfg = @solver.AdaptiveSolverConfig::default()
  let traj = @solver.solve_rk45(model, 15.0, 0.5, cfg, env_fn).unwrap()
  let pco2 = estimate_pco2_microatm(2100.0, 2300.0, 20.0)
  assert_true(pco2 > 300.0 && pco2 < 600.0)
  assert_true(traj.length() > 5)
}
