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

///|
test "element vector follows standard redfield ratios" {
  let vector = ElementVector::from_nitrogen(
    16.0,
    RedfieldRatio::standard(),
    1.0,
  )
  assert_eq(vector.c_val, 106.0)
  assert_eq(vector.n_val, 16.0)
  assert_eq(vector.p_val, 1.0)
  assert_eq(vector.si_val, 16.0)
  assert_eq(vector.o2_val, 138.0)
  let scaled = vector.scale(0.5)
  assert_eq(scaled.c_val, 53.0)
  assert_eq(scaled.o2_val, 69.0)
}

///|
test "molecular diffusivity increases with temperature" {
  let o2_cold = o2_molecular_diffusivity(5.0)
  let o2_warm = o2_molecular_diffusivity(25.0)
  let co2_cold = co2_molecular_diffusivity(5.0)
  let co2_warm = co2_molecular_diffusivity(25.0)
  assert_true(o2_cold > 0.0 && o2_warm > o2_cold)
  assert_true(co2_cold > 0.0 && co2_warm > co2_cold)
}
