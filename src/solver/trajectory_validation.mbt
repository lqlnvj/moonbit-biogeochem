// Structural validation for simulation trajectories.

///|
pub(all) struct TrajectoryValidation {
  point_count : Int
  variable_count : Int
  duration : Double
  min_dt : Double
  max_dt : Double
} derive(Debug)

///|
fn finite_value(value : Double) -> Bool {
  !value.is_nan() && !value.is_inf()
}

///|
fn validate_variable_names(names : Array[String]) -> Result[Unit, String] {
  if names.length() == 0 {
    return Err("Trajectory must define at least one variable")
  }
  for i = 0; i < names.length(); i = i + 1 {
    if names[i] == "" {
      return Err("Trajectory variable names must not be empty")
    }
    for j = 0; j < i; j = j + 1 {
      if names[i] == names[j] {
        return Err("Duplicate trajectory variable: " + names[i])
      }
    }
  }
  Ok(())
}

///|
fn validate_point_data(
  point : TrajectoryPoint,
  variable_count : Int,
  point_index : Int,
) -> Result[Unit, String] {
  if point.values.length() != variable_count {
    return Err(
      "Trajectory point " +
      point_index.to_string() +
      " has " +
      point.values.length().to_string() +
      " values; expected " +
      variable_count.to_string(),
    )
  }
  if !finite_value(point.time) {
    return Err("Trajectory time must be finite")
  }
  if !finite_value(point.dt) || point.dt < 0.0 {
    return Err("Trajectory step size must be finite and non-negative")
  }
  for value in point.values {
    if !finite_value(value) {
      return Err("Trajectory values must be finite")
    }
  }
  Ok(())
}

///|
fn validate_trajectory_contents(
  trajectory : Trajectory,
) -> Result[TrajectoryValidation, String] {
  match validate_variable_names(trajectory.var_names) {
    Ok(_) => ()
    Err(err) => return Err(err)
  }
  if trajectory.points.length() == 0 {
    return Err("Trajectory must contain at least one point")
  }

  let variable_count = trajectory.var_names.length()
  for i = 0; i < trajectory.points.length(); i = i + 1 {
    match validate_point_data(trajectory.points[i], variable_count, i) {
      Ok(_) => ()
      Err(err) => return Err(err)
    }
  }

  let first_time = trajectory.points[0].time
  let mut duration = 0.0
  let mut min_dt = 0.0
  let mut max_dt = 0.0
  if trajectory.points.length() > 1 {
    let first_dt = trajectory.points[1].time - first_time
    min_dt = first_dt
    max_dt = first_dt
    for i = 1; i < trajectory.points.length(); i = i + 1 {
      let previous_time = trajectory.points[i - 1].time
      let current_time = trajectory.points[i].time
      let time_step = current_time - previous_time
      if time_step <= 0.0 {
        return Err("Trajectory time must be strictly increasing")
      }
      if time_step < min_dt {
        min_dt = time_step
      }
      if time_step > max_dt {
        max_dt = time_step
      }
    }
    duration = trajectory.points[trajectory.points.length() - 1].time -
      first_time
  }

  Ok({
    point_count: trajectory.points.length(),
    variable_count,
    duration,
    min_dt,
    max_dt,
  })
}

///|
pub fn Trajectory::validate(
  self : Trajectory,
) -> Result[TrajectoryValidation, String] {
  validate_trajectory_contents(self)
}

///|
fn validate_append_arguments(
  trajectory : Trajectory,
  time : Double,
  values : Array[Double],
  dt : Double,
) -> Result[Unit, String] {
  if values.length() != trajectory.var_names.length() {
    return Err("Trajectory append values have the wrong dimension")
  }
  if !finite_value(time) {
    return Err("Trajectory append time must be finite")
  }
  if !finite_value(dt) || dt < 0.0 {
    return Err("Trajectory append step size must be finite and non-negative")
  }
  for value in values {
    if !finite_value(value) {
      return Err("Trajectory append values must be finite")
    }
  }
  if trajectory.points.length() > 0 {
    let last_time = trajectory.points[trajectory.points.length() - 1].time
    if time <= last_time {
      return Err("Trajectory append time must be strictly increasing")
    }
  }
  Ok(())
}

///|
pub fn Trajectory::try_append(
  self : Trajectory,
  time : Double,
  values : Array[Double],
  dt : Double,
) -> Result[Unit, String] {
  match validate_append_arguments(self, time, values, dt) {
    Ok(_) => ()
    Err(err) => return Err(err)
  }
  self.append(time, values, dt)
  Ok(())
}

///|
pub fn Trajectory::duration(self : Trajectory) -> Result[Double, String] {
  match self.validate() {
    Ok(report) => Ok(report.duration)
    Err(err) => Err(err)
  }
}

///|
pub fn Trajectory::time_step_bounds(
  self : Trajectory,
) -> Result[(Double, Double), String] {
  match self.validate() {
    Ok(report) => Ok((report.min_dt, report.max_dt))
    Err(err) => Err(err)
  }
}
