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

///|
test "reaction kinetics cover limiting and positive regimes" {
  assert_eq(michaelis_menten(-1.0, 1.0), 0.0)
  assert_eq(steele_light_limitation(0.0, 100.0), 0.0)
  assert_eq(steele_light_limitation(100.0, 0.0), 0.0)
  assert_eq(ivlev_grazing(0.5, 1.0, 1.0), 0.0)
  assert_true(ivlev_grazing(2.0, 1.0, 1.0) > 0.0)
  assert_eq(holling_type2(0.0, 1.0, 2.0), 0.0)
  assert_true(holling_type2(1.0, 1.0, 2.0) > 0.0)
  assert_eq(holling_type3(0.0, 1.0, 2.0), 0.0)
  assert_true(holling_type3(1.0, 1.0, 2.0) > 0.0)
  assert_eq(quadratic_mortality(-1.0, 0.2), 0.0)
  assert_eq(quadratic_mortality(2.0, 0.2), 0.8)
  assert_eq(q10_temperature_factor(25.0, 15.0, 2.0), 2.0)
}

///|
test "flux descriptor preserves ecological provenance" {
  let flux = FluxDescriptor::new("grazing", "P", "Z", 0.25, ConcentrationN)
  assert_eq(flux.id, "grazing")
  assert_eq(flux.source_var, "P")
  assert_eq(flux.target_var, "Z")
  assert_eq(flux.rate_value, 0.25)
  assert_eq(flux.unit, ConcentrationN)
}
