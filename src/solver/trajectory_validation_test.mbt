///|
test "trajectory validation rejects empty trajectories" {
  let trajectory = Trajectory::new(["N"])
  let result = trajectory.validate()
  assert_true(result is Err(_))
}

///|
test "checked append rejects a mismatched state dimension" {
  let trajectory = Trajectory::new(["N", "P"])
  let result = trajectory.try_append(0.0, [1.0], 0.0)
  assert_true(result is Err(_))
}

///|
test "validation rejects non-increasing timestamps" {
  let trajectory = Trajectory::new(["N"])
  trajectory.append(0.0, [1.0], 0.0)
  trajectory.append(0.0, [1.1], 0.0)
  assert_true(trajectory.validate() is Err(_))
}

///|
test "validation reports duration and time-step bounds" {
  let trajectory = Trajectory::new(["N"])
  trajectory.append(0.0, [1.0], 0.0)
  trajectory.append(0.5, [1.2], 0.5)
  trajectory.append(1.5, [1.4], 1.0)
  match trajectory.validate() {
    Ok(report) => {
      assert_eq(report.point_count, 3)
      assert_eq(report.variable_count, 1)
      assert_eq(report.duration, 1.5)
      assert_eq(report.min_dt, 0.5)
      assert_eq(report.max_dt, 1.0)
    }
    Err(_) => fail("expected a valid trajectory")
  }
}

///|
test "trajectory validation rejects invalid variable definitions" {
  assert_true(Trajectory::new([""]).validate() is Err(_))
  assert_true(Trajectory::new(["N", "N"]).validate() is Err(_))
  let trajectory = Trajectory::new(["N"])
  trajectory.append(0.0, [1.0], -0.1)
  assert_true(trajectory.validate() is Err(_))
}

///|
test "trajectory helpers expose duration and step bounds" {
  let trajectory = Trajectory::new(["N"])
  trajectory.append(0.0, [1.0], 0.0)
  trajectory.append(0.5, [0.9], 0.5)
  trajectory.append(1.5, [0.7], 1.0)
  match trajectory.duration() {
    Ok(duration) => assert_eq(duration, 1.5)
    Err(_) => fail("expected a valid trajectory duration")
  }
  match trajectory.time_step_bounds() {
    Ok((minimum, maximum)) => {
      assert_eq(minimum, 0.5)
      assert_eq(maximum, 1.0)
    }
    Err(_) => fail("expected valid trajectory time-step bounds")
  }
}

///|
test "checked append rejects invalid step and time values" {
  let trajectory = Trajectory::new(["N"])
  assert_true(trajectory.try_append(0.0, [1.0], -1.0) is Err(_))
  trajectory.try_append(0.0, [1.0], 0.0).unwrap()
  assert_true(trajectory.try_append(0.0, [0.9], 0.0) is Err(_))
}
