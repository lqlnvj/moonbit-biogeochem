// Integration tests for advanced Silicon and Microbial Loop models

///|
test "npzd silicon diatom model run" {
  let model = create_npzd_silicon_model(15.0, 20.0, 0.5, 0.5, 0.1, 0.2)
  let env_fn = fn(t) { @types.EnvironmentForcing::seasonal_forcing(t, 45.0) }
  let traj = @solver.solve_rk4(model, 5.0, 0.5, env_fn).unwrap()
  assert_true(traj.length() > 5)
}

///|
test "microbial loop model run" {
  let model = create_microbial_loop_model(100.0, 10.0, 2.0, 5.0)
  let env_fn = fn(_t) { @types.EnvironmentForcing::default_surface() }
  let traj = @solver.solve_euler(model, 5.0, 0.2, env_fn).unwrap()
  assert_true(traj.length() > 5)
}

///|
test "iron limited model evolves iron and nutrient compartments" {
  let model = create_npzd_iron_model(15.0, 0.2, 0.5, 0.1, 0.2)
  let env_fn = fn(_t) { @types.EnvironmentForcing::default_surface() }
  let traj = @solver.solve_rk4(model, 3.0, 0.25, env_fn).unwrap()
  let iron = traj.get_time_series("Fe").unwrap()
  let nutrient = traj.get_time_series("N").unwrap()
  assert_true(traj.length() > 10)
  assert_true(iron[iron.length() - 1] >= 0.0)
  assert_true(nutrient[nutrient.length() - 1] >= 0.0)
}

///|
test "extended npzdd model keeps benthic and detritus pools nonnegative" {
  let model = create_npzdd_model(15.0, 0.5, 0.2, 0.1, 0.05, 1.0)
  let env_fn = fn(_t) { @types.EnvironmentForcing::default_surface() }
  let traj = @solver.solve_rk4(model, 4.0, 0.25, env_fn).unwrap()
  let slow_detritus = traj.get_time_series("SD").unwrap()
  let fast_detritus = traj.get_time_series("FD").unwrap()
  let benthic = traj.get_time_series("BEN").unwrap()
  assert_true(traj.length() > 10)
  assert_true(slow_detritus[slow_detritus.length() - 1] >= 0.0)
  assert_true(fast_detritus[fast_detritus.length() - 1] >= 0.0)
  assert_true(benthic[benthic.length() - 1] >= 0.0)
}

///|
test "ocean carbon model conserves alkalinity" {
  let model = create_ocean_carbon_model(2100.0, 2300.0)
  let env_fn = fn(_t) { @types.EnvironmentForcing::default_surface() }
  let traj = @solver.solve_rk4(model, 2.0, 0.2, env_fn).unwrap()
  let alkalinity = traj.get_time_series("TA").unwrap()
  let final_ta = alkalinity[alkalinity.length() - 1]
  assert_true((final_ta - 2300.0).abs() < 1.0e-9)
}
