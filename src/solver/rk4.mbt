// Classic 4th-Order Runge-Kutta (RK4) Numerical Integration Solver

pub fn rk4_step(
  evaluator : @core.DerivativeEvaluator,
  t : Double,
  y : Array[Double],
  dt : Double,
  env_provider : (Double) -> @types.EnvironmentForcing,
  params : @types.ParameterMap
) -> Array[Double] {
  let dim = y.length()
  
  // Stage 1
  let env1 = env_provider(t)
  let k1 = evaluator.compute(t, y, env1, params)
  
  // Stage 2
  let y_k2 = Array::make(dim, 0.0)
  for i = 0; i < dim; i = i + 1 {
    y_k2[i] = y[i] + 0.5 * dt * k1[i]
  }
  let env2 = env_provider(t + 0.5 * dt)
  let k2 = evaluator.compute(t + 0.5 * dt, y_k2, env2, params)
  
  // Stage 3
  let y_k3 = Array::make(dim, 0.0)
  for i = 0; i < dim; i = i + 1 {
    y_k3[i] = y[i] + 0.5 * dt * k2[i]
  }
  let env3 = env_provider(t + 0.5 * dt)
  let k3 = evaluator.compute(t + 0.5 * dt, y_k3, env3, params)
  
  // Stage 4
  let y_k4 = Array::make(dim, 0.0)
  for i = 0; i < dim; i = i + 1 {
    y_k4[i] = y[i] + dt * k3[i]
  }
  let env4 = env_provider(t + dt)
  let k4 = evaluator.compute(t + dt, y_k4, env4, params)
  
  // Combine stages: y_{n+1} = y_n + dt/6 * (k1 + 2*k2 + 2*k3 + k4)
  let y_next = Array::make(dim, 0.0)
  for i = 0; i < dim; i = i + 1 {
    let updated = y[i] + (dt / 6.0) * (k1[i] + 2.0 * k2[i] + 2.0 * k3[i] + k4[i])
    y_next[i] = if updated < 0.0 { 0.0 } else { updated }
  }
  y_next
}

pub fn solve_rk4(
  model : @core.BoxModel,
  t_end : Double,
  dt : Double,
  env_provider : (Double) -> @types.EnvironmentForcing
) -> Result[Trajectory, String] {
  let var_names = model.current_state.names()
  let traj = Trajectory::new(var_names)
  
  let mut curr_time = model.current_time
  let mut curr_y = model.current_state.to_array()
  
  traj.append(curr_time, curr_y, dt)
  
  while curr_time < t_end {
    let step_dt = if curr_time + dt > t_end {
      t_end - curr_time
    } else {
      dt
    }
    
    let next_y = rk4_step(model.evaluator, curr_time, curr_y, step_dt, env_provider, model.config.parameters)
    curr_time = curr_time + step_dt
    curr_y = next_y
    traj.append(curr_time, curr_y, step_dt)
  }
  
  Ok(traj)
}
