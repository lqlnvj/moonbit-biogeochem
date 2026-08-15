// Implicit Euler Solver for Stiff Biogeochemical Differential Equations

///|
pub fn solve_implicit_euler_step(
  evaluator : @core.DerivativeEvaluator,
  t_next : Double,
  y_curr : Array[Double],
  dt : Double,
  env : @types.EnvironmentForcing,
  params : @types.ParameterMap,
  max_iters : Int,
  tol : Double,
) -> Array[Double] {
  let dim = y_curr.length()
  let y_guess = y_curr.copy()
  let mut converged = false
  let mut iter = 0

  while !converged && iter < max_iters {
    let f_guess = evaluator.compute(t_next, y_guess, env, params)
    let mut max_diff = 0.0

    let y_next = Array::make(dim, 0.0)
    for i = 0; i < dim; i = i + 1 {
      // Fixed point iteration: y_{n+1} = y_n + dt * f(t_{n+1}, y_{n+1})
      let target = y_curr[i] + dt * f_guess[i]
      let non_neg = if target < 0.0 { 0.0 } else { target }
      let diff = (non_neg - y_guess[i]).abs()
      if diff > max_diff {
        max_diff = diff
      }
      y_next[i] = non_neg
    }

    if max_diff < tol {
      converged = true
    }
    for i = 0; i < dim; i = i + 1 {
      y_guess[i] = y_next[i]
    }
    iter = iter + 1
  }

  y_guess
}

///|
pub fn solve_implicit_euler(
  model : @core.BoxModel,
  t_end : Double,
  dt : Double,
  env_provider : (Double) -> @types.EnvironmentForcing,
) -> Result[Trajectory, String] {
  let var_names = model.current_state.names()
  let traj = Trajectory::new(var_names)

  let mut curr_time = model.current_time
  let mut curr_y = model.current_state.to_array()

  traj.append(curr_time, curr_y, dt)

  while curr_time < t_end {
    let step_dt = if curr_time + dt > t_end { t_end - curr_time } else { dt }

    let next_time = curr_time + step_dt
    let env_next = env_provider(next_time)
    let next_y = solve_implicit_euler_step(
      model.evaluator,
      next_time,
      curr_y,
      step_dt,
      env_next,
      model.config.parameters,
      20,
      1.0e-5,
    )

    curr_time = next_time
    curr_y = next_y
    traj.append(curr_time, curr_y, step_dt)
  }

  Ok(traj)
}
