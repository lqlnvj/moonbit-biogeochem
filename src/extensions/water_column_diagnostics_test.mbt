///|
test "checked water column construction rejects zero layers" {
  assert_true(WaterColumn1D::try_create(0, 50.0, [1.0]) is Err(_))
}

///|
test "checked water column construction rejects negative initial values" {
  assert_true(WaterColumn1D::try_create(2, 50.0, [-1.0]) is Err(_))
}

///|
test "stability limit rejects non-positive spacing and coefficients" {
  assert_true(water_column_stability_limit(0.0, 1.0, 0.5) is Err(_))
  assert_true(water_column_stability_limit(1.0, -1.0, 0.5) is Err(_))
}

///|
test "valid one-layer column reports inventory and non-negative state" {
  let column = WaterColumn1D::try_create(1, 10.0, [2.0, 3.0]).unwrap()
  let report = validate_water_column(column).unwrap()
  assert_eq(report.layer_count, 1)
  assert_eq(report.state_dimension, 2)
  assert_eq(report.total_inventory, 50.0)
  assert_true(report.non_negative)
}

///|
test "water column step diagnostics identify unstable transport" {
  let column = WaterColumn1D::try_create(2, 10.0, [2.0]).unwrap()
  let stable = assess_water_column_step(column, 1.0, 0.5, 1.0).unwrap()
  let unstable = assess_water_column_step(column, 1.0, 0.5, 25.0).unwrap()
  assert_true(stable.stable)
  assert_true(!unstable.stable)
  assert_true(unstable.maximum_cfl > 1.0)
}
