// Unit tests for src/core module

///|
test "michaelis menten kinetics" {
  let lim0 = michaelis_menten(0.0, 1.0)
  inspect(lim0, content="0")
  let lim1 = michaelis_menten(1.0, 1.0)
  inspect(lim1, content="0.5")
}

///|
test "steele light limitation" {
  let lim_opt = steele_light_limitation(100.0, 100.0)
  inspect(lim_opt, content="1")
}

///|
test "redfield stoichiometry ratios" {
  let r = RedfieldRatio::standard()
  let nc = r.n_to_c()
  inspect(nc, content="0.1509433962264151")
}

///|
test "mass conservation auditor" {
  let audit = MassConservationCheck::audit(100.0, 99.9999, 1.0e-4)
  inspect(audit.is_conserved, content="true")
}

///|
test "o2 solubility saturation" {
  let o2_sat = o2_solubility_saturation(15.0, 35.0)
  assert_true(o2_sat > 200.0)
}
