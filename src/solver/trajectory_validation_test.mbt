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
