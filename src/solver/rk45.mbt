// Adaptive Step-Size Dormand-Prince / RKF45 Numerical Solver

///|
pub(all) struct AdaptiveSolverConfig {
  abs_tol : Double
  rel_tol : Double
  min_dt : Double
  max_dt : Double
  safety_factor : Double
} derive(Debug)

///|
pub fn AdaptiveSolverConfig::default() -> AdaptiveSolverConfig {
  {
    abs_tol: 1.0e-6,
    rel_tol: 1.0e-5,
    min_dt: 1.0e-5,
    max_dt: 1.0,
    safety_factor: 0.84,
  }
}

///|
pub fn solve_rk45(
  model : @core.BoxModel,
  t_end : Double,
  initial_dt : Double,
  config : AdaptiveSolverConfig,
  env_provider : (Double) -> @types.EnvironmentForcing,
) -> Result[Trajectory, String] {
  let var_names = model.current_state.names()
  let traj = Trajectory::new(var_names)

  let mut curr_time = model.current_time
  let mut curr_y = model.current_state.to_array()
  let mut current_dt = initial_dt
  let dim = curr_y.length()

  traj.append(curr_time, curr_y, current_dt)

  while curr_time < t_end {
    let mut step_accepted = false
    let mut trial_dt = current_dt

    if curr_time + trial_dt > t_end {
      trial_dt = t_end - curr_time
    }

    let mut next_y = Array::make(dim, 0.0)
    let mut error_ratio = 1.0

    while !step_accepted {
      // 4th order RK approximation
      let y4 = rk4_step(
        model.evaluator,
        curr_time,
        curr_y,
        trial_dt,
        env_provider,
        model.config.parameters,
      )

      // Euler 1st order step to estimate local truncation error
      let env0 = env_provider(curr_time)
      let derivs = model.evaluator.compute(
        curr_time,
        curr_y,
        env0,
        model.config.parameters,
      )
      let y1 = Array::make(dim, 0.0)
      for i = 0; i < dim; i = i + 1 {
        y1[i] = curr_y[i] + derivs[i] * trial_dt
      }

      // Calculate max truncation error
      let mut max_err = 0.0
      for i = 0; i < dim; i = i + 1 {
        let err = (y4[i] - y1[i]).abs()
        let tol = config.abs_tol + config.rel_tol * curr_y[i].abs()
        let ratio = err / tol
        if ratio > max_err {
          max_err = ratio
        }
      }

      error_ratio = max_err
      if error_ratio <= 1.0 || trial_dt <= config.min_dt {
        step_accepted = true
        next_y = y4
      } else {
        // Shrink step size
        let scale = config.safety_factor * @math.pow(1.0 / error_ratio, 0.25)
        let scaled_dt = trial_dt * scale
        trial_dt = if scaled_dt < config.min_dt {
          config.min_dt
        } else {
          scaled_dt
        }
      }
    }

    curr_time = curr_time + trial_dt
    curr_y = next_y
    traj.append(curr_time, curr_y, trial_dt)

    // Adapt step size for next iteration
    let scale = if error_ratio > 0.0 {
      config.safety_factor * @math.pow(1.0 / error_ratio, 0.2)
    } else {
      1.5
    }
    let next_dt = current_dt * scale
    current_dt = if next_dt > config.max_dt {
      config.max_dt
    } else if next_dt < config.min_dt {
      config.min_dt
    } else {
      next_dt
    }
  }

  Ok(traj)
}
