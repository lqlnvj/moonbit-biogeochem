// Forward Euler Numerical Solver

pub fn solve_euler(
  model : @core.BoxModel,
  t_end : Double,
  dt : Double,
  env_provider : (Double) -> @types.EnvironmentForcing
) -> Result[Trajectory, String] {
  let var_names = model.current_state.names()
  let traj = Trajectory::new(var_names)
  
  let mut curr_time = model.current_time
  let mut curr_y = model.current_state.to_array()
  let dim = curr_y.length()
  
  traj.append(curr_time, curr_y, dt)
  
  while curr_time < t_end {
    let step_dt = if curr_time + dt > t_end {
      t_end - curr_time
    } else {
      dt
    }
    
    let env = env_provider(curr_time)
    let derivs = model.evaluator.compute(curr_time, curr_y, env, model.config.parameters)
    
    let next_y = Array::make(dim, 0.0)
    for i = 0; i < dim; i = i + 1 {
      let updated = curr_y[i] + derivs[i] * step_dt
      // Non-negative constraint for ecological concentrations
      next_y[i] = if updated < 0.0 { 0.0 } else { updated }
    }
    
    curr_time = curr_time + step_dt
    curr_y = next_y
    traj.append(curr_time, curr_y, step_dt)
  }
  
  Ok(traj)
}
