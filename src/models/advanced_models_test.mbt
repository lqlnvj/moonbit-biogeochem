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
