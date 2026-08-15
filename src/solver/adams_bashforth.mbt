// Adams-Bashforth Multi-Step Numerical Integration Solvers (AB2 & AB3)

///|
pub fn solve_adams_bashforth_2(
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

  // Step 1: Bootstrap using RK4
  let env0 = env_provider(curr_time)
  let f0 = model.evaluator.compute(
    curr_time,
    curr_y,
    env0,
    model.config.parameters,
  )

  let next_y_rk = rk4_step(
    model.evaluator,
    curr_time,
    curr_y,
    dt,
    env_provider,
    model.config.parameters,
  )
  curr_time = curr_time + dt
  let mut prev_f = f0
  curr_y = next_y_rk
  traj.append(curr_time, curr_y, dt)

  // Step 2..N: Adams-Bashforth 2nd Order: y_{n+1} = y_n + dt/2 * (3*f_n - f_{n-1})
  while curr_time < t_end {
    let step_dt = if curr_time + dt > t_end { t_end - curr_time } else { dt }

    let env_n = env_provider(curr_time)
    let f_n = model.evaluator.compute(
      curr_time,
      curr_y,
      env_n,
      model.config.parameters,
    )

    let y_next = Array::make(dim, 0.0)
    for i = 0; i < dim; i = i + 1 {
      let step_val = curr_y[i] + 0.5 * step_dt * (3.0 * f_n[i] - prev_f[i])
      y_next[i] = if step_val < 0.0 { 0.0 } else { step_val }
    }

    prev_f = f_n
    curr_time = curr_time + step_dt
    curr_y = y_next
    traj.append(curr_time, curr_y, step_dt)
  }

  Ok(traj)
}

///|
pub fn solve_adams_bashforth_3(
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

  // Bootstrap step 1 & 2 using RK4
  let env0 = env_provider(curr_time)
  let f0 = model.evaluator.compute(
    curr_time,
    curr_y,
    env0,
    model.config.parameters,
  )

  let y1 = rk4_step(
    model.evaluator,
    curr_time,
    curr_y,
    dt,
    env_provider,
    model.config.parameters,
  )
  let env1 = env_provider(curr_time + dt)
  let f1 = model.evaluator.compute(
    curr_time + dt,
    y1,
    env1,
    model.config.parameters,
  )
  traj.append(curr_time + dt, y1, dt)

  let y2 = rk4_step(
    model.evaluator,
    curr_time + dt,
    y1,
    dt,
    env_provider,
    model.config.parameters,
  )
  let env2 = env_provider(curr_time + 2.0 * dt)
  let f2 = model.evaluator.compute(
    curr_time + 2.0 * dt,
    y2,
    env2,
    model.config.parameters,
  )
  traj.append(curr_time + 2.0 * dt, y2, dt)

  curr_time = curr_time + 2.0 * dt
  curr_y = y2

  let mut fn_minus_2 = f0
  let mut fn_minus_1 = f1
  let mut fn_curr = f2

  // AB3 iteration: y_{n+1} = y_n + dt/12 * (23*f_n - 16*f_{n-1} + 5*f_{n-2})
  while curr_time < t_end {
    let step_dt = if curr_time + dt > t_end { t_end - curr_time } else { dt }

    let y_next = Array::make(dim, 0.0)
    for i = 0; i < dim; i = i + 1 {
      let step_val = curr_y[i] +
        step_dt /
        12.0 *
        (23.0 * fn_curr[i] - 16.0 * fn_minus_1[i] + 5.0 * fn_minus_2[i])
      y_next[i] = if step_val < 0.0 { 0.0 } else { step_val }
    }

    curr_time = curr_time + step_dt
    curr_y = y_next
    traj.append(curr_time, curr_y, step_dt)

    fn_minus_2 = fn_minus_1
    fn_minus_1 = fn_curr
    let env_next = env_provider(curr_time)
    fn_curr = model.evaluator.compute(
      curr_time,
      curr_y,
      env_next,
      model.config.parameters,
    )
  }

  Ok(traj)
}
