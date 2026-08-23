// Deterministic statistics and event metrics for model trajectories.

///|
pub(all) struct SeriesStatistics {
  count : Int
  minimum : Double
  maximum : Double
  mean : Double
  integral : Double
  trend : Double
  finite : Bool
} derive(Debug)

///|
pub(all) enum ThresholdDirection {
  Rising
  Falling
} derive(Debug, Eq)

///|
pub(all) struct ThresholdCrossing {
  time : Double
  value : Double
  direction : ThresholdDirection
} derive(Debug)

///|
pub(all) struct TrajectorySummary {
  duration : Double
  minimum_step : Double
  maximum_step : Double
  variable_names : Array[String]
} derive(Debug)

///|
fn finite_metric_value(value : Double) -> Bool {
  !value.is_nan() && !value.is_inf()
}

///|
fn validate_series_inputs(
  times : Array[Double],
  values : Array[Double],
) -> Result[Unit, String] {
  if times.length() == 0 {
    return Err("Series must contain at least one sample")
  }
  if times.length() != values.length() {
    return Err("Series time and value arrays must have equal length")
  }
  for i = 0; i < times.length(); i = i + 1 {
    if !finite_metric_value(times[i]) {
      return Err("Series timestamps must be finite")
    }
    if !finite_metric_value(values[i]) {
      return Err("Series values must be finite")
    }
    if i > 0 && times[i] <= times[i - 1] {
      return Err("Series timestamps must be strictly increasing")
    }
  }
  Ok(())
}

///|
pub fn summarize_series(
  times : Array[Double],
  values : Array[Double],
) -> Result[SeriesStatistics, String] {
  match validate_series_inputs(times, values) {
    Err(err) => return Err(err)
    Ok(_) => ()
  }

  let count = values.length()
  let mut minimum = values[0]
  let mut maximum = values[0]
  let mut sum_y = 0.0
  let mut sum_t = 0.0
  let mut sum_tt = 0.0
  let mut sum_ty = 0.0
  let mut integral = 0.0
  for i = 0; i < count; i = i + 1 {
    let time = times[i]
    let value = values[i]
    if value < minimum {
      minimum = value
    }
    if value > maximum {
      maximum = value
    }
    sum_y = sum_y + value
    sum_t = sum_t + time
    sum_tt = sum_tt + time * time
    sum_ty = sum_ty + time * value
    if i > 0 {
      let dt = time - times[i - 1]
      integral = integral + dt * (values[i - 1] + value) / 2.0
    }
  }

  let n = count.to_double()
  let denominator = n * sum_tt - sum_t * sum_t
  let trend = if denominator.abs() < 1.0e-12 {
    0.0
  } else {
    (n * sum_ty - sum_t * sum_y) / denominator
  }
  Ok({
    count,
    minimum,
    maximum,
    mean: sum_y / n,
    integral,
    trend,
    finite: true,
  })
}

///|
fn crossing_time(
  time_a : Double,
  time_b : Double,
  value_a : Double,
  value_b : Double,
  threshold : Double,
) -> Double {
  if value_a == value_b {
    time_a
  } else {
    time_a + (threshold - value_a) / (value_b - value_a) * (time_b - time_a)
  }
}

///|
pub fn find_threshold_crossings(
  times : Array[Double],
  values : Array[Double],
  threshold : Double,
) -> Result[Array[ThresholdCrossing], String] {
  match validate_series_inputs(times, values) {
    Err(err) => return Err(err)
    Ok(_) => ()
  }
  if !finite_metric_value(threshold) {
    return Err("Threshold must be finite")
  }

  let crossings = Array::new()
  for i = 0; i < values.length() - 1; i = i + 1 {
    let value_a = values[i]
    let value_b = values[i + 1]
    let direction : ThresholdDirection? = if value_a < threshold && value_b >= threshold {
      Some(Rising)
    } else if value_a > threshold && value_b <= threshold {
      Some(Falling)
    } else if value_a == threshold && value_b > threshold {
      Some(Rising)
    } else if value_a == threshold && value_b < threshold {
      Some(Falling)
    } else {
      None
    }
    match direction {
      Some(kind) => crossings.push({
        time: crossing_time(
          times[i], times[i + 1], value_a, value_b, threshold,
        ),
        value: threshold,
        direction: kind,
      })
      None => ()
    }
  }
  Ok(crossings)
}

///|
pub fn compute_duration_below_threshold(
  times : Array[Double],
  values : Array[Double],
  threshold : Double,
) -> Result[Double, String] {
  match validate_series_inputs(times, values) {
    Err(err) => return Err(err)
    Ok(_) => ()
  }
  if !finite_metric_value(threshold) {
    return Err("Threshold must be finite")
  }
  let mut duration = 0.0
  for i = 0; i < values.length() - 1; i = i + 1 {
    let value_a = values[i]
    let value_b = values[i + 1]
    let dt = times[i + 1] - times[i]
    if value_a < threshold && value_b < threshold {
      duration = duration + dt
    } else if value_a < threshold && value_b >= threshold {
      let fraction = (threshold - value_a) / (value_b - value_a)
      duration = duration + dt * fraction
    } else if value_a >= threshold && value_b < threshold {
      let fraction = (threshold - value_a) / (value_b - value_a)
      duration = duration + dt * (1.0 - fraction)
    }
  }
  Ok(duration)
}

///|
pub fn summarize_trajectory(
  trajectory : @solver.Trajectory,
) -> Result[TrajectorySummary, String] {
  match trajectory.validate() {
    Err(err) => Err(err)
    Ok(report) => Ok({
      duration: report.duration,
      minimum_step: report.min_dt,
      maximum_step: report.max_dt,
      variable_names: trajectory.var_names.copy(),
    })
  }
}
