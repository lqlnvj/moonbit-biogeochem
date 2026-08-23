///|
test "series statistics use trapezoidal integration" {
  let result = summarize_series([0.0, 1.0, 2.0], [0.0, 2.0, 2.0])
  match result {
    Ok(stats) => {
      assert_eq(stats.count, 3)
      assert_eq(stats.minimum, 0.0)
      assert_eq(stats.maximum, 2.0)
      assert_eq(stats.mean, 4.0 / 3.0)
      assert_eq(stats.integral, 3.0)
    }
    Err(_) => fail("expected valid series")
  }
}

///|
test "threshold crossings interpolate time and direction" {
  let result = find_threshold_crossings([0.0, 2.0, 4.0], [0.0, 4.0, 0.0], 2.0)
  match result {
    Ok(crossings) => {
      assert_eq(crossings.length(), 2)
      assert_true(crossings[0].direction is Rising)
      assert_true(crossings[1].direction is Falling)
      assert_eq(crossings[0].time, 1.0)
      assert_eq(crossings[1].time, 3.0)
    }
    Err(_) => fail("expected valid crossings")
  }
}

///|
test "duration below threshold integrates partial segments" {
  let result = compute_duration_below_threshold(
    [0.0, 2.0, 4.0],
    [0.0, 4.0, 0.0],
    2.0,
  )
  match result {
    Ok(duration) => assert_eq(duration, 2.0)
    Err(_) => fail("expected a valid duration")
  }
}

///|
test "statistics reject mismatched and non-increasing inputs" {
  assert_true(summarize_series([0.0], [1.0, 2.0]) is Err(_))
  assert_true(summarize_series([0.0, 0.0], [1.0, 2.0]) is Err(_))
}

///|
test "trajectory summary reports duration and variable names" {
  let trajectory = @solver.Trajectory::new(["O2"])
  trajectory.append(0.0, [4.0], 0.0)
  trajectory.append(1.0, [3.0], 1.0)
  match summarize_trajectory(trajectory) {
    Ok(summary) => {
      assert_eq(summary.duration, 1.0)
      assert_eq(summary.minimum_step, 1.0)
      assert_eq(summary.maximum_step, 1.0)
      assert_eq(summary.variable_names, ["O2"])
    }
    Err(_) => fail("expected a valid trajectory summary")
  }
}
