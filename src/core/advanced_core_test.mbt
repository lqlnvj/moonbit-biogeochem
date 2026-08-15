// Unit tests for advanced core kinetics & thermodynamics

///|
test "droop cell quota limitation" {
  let lim = droop_cell_quota_limitation(2.0, 1.0)
  inspect(lim, content="0.5")
}

///|
test "liebig minimum limitation" {
  let min_lim = liebig_minimum_limitation([0.8, 0.3, 0.5])
  inspect(min_lim, content="0.3")
}

///|
test "seawater density calculation" {
  let rho = seawater_density_eos80(15.0, 35.0)
  assert_true(rho > 1020.0 && rho < 1030.0)
}
