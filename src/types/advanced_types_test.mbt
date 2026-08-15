// Unit tests for advanced types

///|
test "unit converter functions" {
  let kelvin = convert_celsius_to_kelvin(25.0)
  inspect(kelvin, content="298.15")
  let chl = convert_mmol_n_m3_to_mg_chl_m3(1.0, 6.625, 0.02)
  assert_true(chl > 0.0)
}

///|
test "spectral irradiance attenuation" {
  let spec = SpectralIrradiance::from_total_par(100.0)
  let att = spec.attenuate_at_depth(10.0, 0.5)
  assert_true(att.total() < spec.total())
}

///|
test "bounds violation validation" {
  let v1 = StateVariable::{
    id: "N",
    name: "Nutrient",
    unit: ConcentrationN,
    value: -5.0,
    min_val: 0.0,
    max_val: 100.0,
  }
  let state = StateVector::new([v1])
  let violations = validate_state_vector_bounds(state)
  inspect(violations.length(), content="1")
}
