// Simulation Trajectory Data Structure and Analysis

pub(all) struct TrajectoryPoint {
  time : Double
  values : Array[Double]
  dt : Double
} derive(Debug)

pub fn TrajectoryPoint::new(time : Double, values : Array[Double], dt : Double) -> TrajectoryPoint {
  { time, values: values.copy(), dt }
}

pub(all) struct Trajectory {
  var_names : Array[String]
  points : Array[TrajectoryPoint]
} derive(Debug)

pub fn Trajectory::new(var_names : Array[String]) -> Trajectory {
  { var_names: var_names.copy(), points: Array::new() }
}

pub fn Trajectory::append(self : Trajectory, time : Double, values : Array[Double], dt : Double) -> Unit {
  self.points.push(TrajectoryPoint::new(time, values, dt))
}

pub fn Trajectory::length(self : Trajectory) -> Int {
  self.points.length()
}

pub fn Trajectory::get_time_series(self : Trajectory, var_name : String) -> Result[Array[Double], String] {
  let mut target_idx = -1
  for i = 0; i < self.var_names.length(); i = i + 1 {
    if self.var_names[i] == var_name {
      target_idx = i
      break
    }
  }
  if target_idx < 0 {
    return Err("Variable not found in trajectory: " + var_name)
  }
  let series = Array::make(self.points.length(), 0.0)
  for i = 0; i < self.points.length(); i = i + 1 {
    series[i] = self.points[i].values[target_idx]
  }
  Ok(series)
}

pub fn Trajectory::get_timestamps(self : Trajectory) -> Array[Double] {
  let times = Array::make(self.points.length(), 0.0)
  for i = 0; i < self.points.length(); i = i + 1 {
    times[i] = self.points[i].time
  }
  times
}
