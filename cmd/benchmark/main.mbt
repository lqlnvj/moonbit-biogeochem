// Deterministic native workloads used for local performance measurement.

///|
fn print_npzd_benchmark() -> Unit {
  let model = @models.create_npzd_model(15.0, 0.5, 0.1, 0.2)
  let env_fn = fn(t) { @types.EnvironmentForcing::seasonal_forcing(t, 45.0) }
  match @solver.solve_rk4(model, 30.0, 0.25, env_fn) {
    Ok(trajectory) => {
      let series = trajectory.get_time_series("P").unwrap()
      let summary = @analysis.summarize_series(
        trajectory.get_timestamps(), series,
      ).unwrap()
      let final_value = series[series.length() - 1]
      println(
        "npzd,rk4," +
        trajectory.length().to_string() +
        "," +
        final_value.to_string() +
        "," +
        summary.integral.to_string(),
      )
    }
    Err(err) => println("ERROR,npzd,rk4," + err)
  }
}

///|
fn print_coupled_benchmark() -> Unit {
  let model = @models.create_coupled_carbon_npzd_model(
    12.0, 0.8, 0.2, 0.1, 240.0, 2100.0, 2300.0,
  )
  let env_fn = fn(t) { @types.EnvironmentForcing::seasonal_forcing(t, 45.0) }
  let config = @solver.AdaptiveSolverConfig::default()
  match @solver.solve_rk45(model, 20.0, 0.25, config, env_fn) {
    Ok(trajectory) => {
      let series = trajectory.get_time_series("DIC").unwrap()
      let summary = @analysis.summarize_series(
        trajectory.get_timestamps(), series,
      ).unwrap()
      let final_value = series[series.length() - 1]
      println(
        "coupled_carbon,rk45," +
        trajectory.length().to_string() +
        "," +
        final_value.to_string() +
        "," +
        summary.integral.to_string(),
      )
    }
    Err(err) => println("ERROR,coupled_carbon,rk45," + err)
  }
}

///|
fn main {
  println("workload,solver,steps,final_metric,integral_metric")
  print_npzd_benchmark()
  print_coupled_benchmark()
}
