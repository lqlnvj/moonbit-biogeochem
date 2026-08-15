// Trapezoidal Predictor-Corrector Numerical Integration Solver

///|
pub fn solve_trapezoidal(
  model : @core.BoxModel,
  t_end : Double,
  dt : Double,
  env_provider : (Double) -> @types.EnvironmentForcing,
) -> Result[Trajectory, String] {
  let var_names = model.current_state.names()
  let traj = Trajectory::new(var_names)

  let mut curr_time = model.current_time
  let mut curr_y = model.current_state.to_array()
  let dim = curr_y.length()

  traj.append(curr_time, curr_y, dt)

  while curr_time < t_end {
    let step_dt = if curr_time + dt > t_end { t_end - curr_time } else { dt }

    let env_curr = env_provider(curr_time)
    let k1 = model.evaluator.compute(
      curr_time,
      curr_y,
      env_curr,
      model.config.parameters,
    )

    // Predictor (Euler step)
    let y_pred = Array::make(dim, 0.0)
    for i = 0; i < dim; i = i + 1 {
      let p = curr_y[i] + step_dt * k1[i]
      y_pred[i] = if p < 0.0 { 0.0 } else { p }
    }

    // Corrector (Trapezoidal average)
    let next_time = curr_time + step_dt
    let env_next = env_provider(next_time)
    let k2 = model.evaluator.compute(
      next_time,
      y_pred,
      env_next,
      model.config.parameters,
    )

    let next_y = Array::make(dim, 0.0)
    for i = 0; i < dim; i = i + 1 {
      let c = curr_y[i] + 0.5 * step_dt * (k1[i] + k2[i])
      next_y[i] = if c < 0.0 { 0.0 } else { c }
    }

    curr_time = next_time
    curr_y = next_y
    traj.append(curr_time, curr_y, step_dt)
  }

  Ok(traj)
}
