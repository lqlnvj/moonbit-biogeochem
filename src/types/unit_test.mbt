// Unit tests for src/types module

///|
test "physical quantity creation and scaling" {
  let q = PhysicalQuantity::new(10.0, ConcentrationN, "DIN")
  inspect(q.value, content="10")
  let scaled = scale_quantity(q, 2.5)
  inspect(scaled.value, content="25")
}

///|
test "state variable clamping and bounds" {
  let v = StateVariable::new(
    "P",
    "Phytoplankton",
    ConcentrationN,
    5.0,
    0.0,
    10.0,
  )
  inspect(v.value, content="5")
  let v_clamped = StateVariable::new(
    "P",
    "Phytoplankton",
    ConcentrationN,
    15.0,
    0.0,
    10.0,
  )
  inspect(v_clamped.value, content="10")
}

///|
test "state vector indexing and updates" {
  let v1 = StateVariable::new("N", "Nutrient", ConcentrationN, 2.0, 0.0, 50.0)
  let v2 = StateVariable::new(
    "P",
    "Phytoplankton",
    ConcentrationN,
    0.5,
    0.0,
    20.0,
  )
  let vec = StateVector::new([v1, v2])
  inspect(vec.dimension(), content="2")
  let val = vec.get("N").unwrap()
  inspect(val, content="2")

  let updated_vec = vec.set("P", 1.2).unwrap()
  let p_val = updated_vec.get("P").unwrap()
  inspect(p_val, content="1.2")
}

///|
test "parameter map lookup and bounds" {
  let p1 = ModelParameter::new(
    "mu_max",
    "Max Growth Rate",
    1.5,
    RatePerDay,
    0.1,
    3.0,
    "Max phytoplankton growth rate",
  )
  let map = ParameterMap::from_array([p1])
  let val = map.get("mu_max").unwrap()
  inspect(val, content="1.5")
}

///|
test "seasonal environment forcing" {
  let env = EnvironmentForcing::seasonal_forcing(180.0, 45.0)
  inspect(env.time_day, content="180")
  assert_true(env.temperature > 10.0)
}

///|
test "physical quantity conversions and compatibility errors" {
  let nitrogen = PhysicalQuantity::new(10.0, ConcentrationN, "DIN")
  let mass = PhysicalQuantity::convert_concentration_n_to_mass(nitrogen).unwrap()
  assert_true((mass.value - 0.140067).abs() < 1.0e-9)
  assert_eq(mass.unit, ConcentrationMass)

  let invalid_mass = PhysicalQuantity::dimensionless(1.0, "ratio")
  assert_true(
    PhysicalQuantity::convert_concentration_n_to_mass(invalid_mass) is Err(_),
  )

  let rate = PhysicalQuantity::new(0.864, RatePerDay, "growth")
  let per_second = PhysicalQuantity::convert_rate_day_to_sec(rate).unwrap()
  assert_true((per_second.value - 1.0e-5).abs() < 1.0e-12)
  assert_eq(per_second.unit, RatePerSecond)
  assert_true(PhysicalQuantity::convert_rate_day_to_sec(nitrogen) is Err(_))

  let added = add_quantities(
    nitrogen,
    PhysicalQuantity::new(2.0, ConcentrationN, "runoff"),
  ).unwrap()
  assert_eq(added.value, 12.0)
  let subtracted = sub_quantities(
    nitrogen,
    PhysicalQuantity::new(2.0, ConcentrationN, "uptake"),
  ).unwrap()
  assert_eq(subtracted.value, 8.0)
  assert_true(add_quantities(nitrogen, rate) is Err(_))
  assert_true(sub_quantities(nitrogen, rate) is Err(_))
}

///|
test "unit symbols cover the public unit vocabulary" {
  let symbols = [
    unit_symbol(ConcentrationN),
    unit_symbol(ConcentrationP),
    unit_symbol(ConcentrationC),
    unit_symbol(ConcentrationO),
    unit_symbol(ConcentrationMass),
    unit_symbol(RatePerDay),
    unit_symbol(RatePerSecond),
    unit_symbol(Flux),
    unit_symbol(Velocity),
    unit_symbol(Depth),
    unit_symbol(Temperature),
    unit_symbol(Salinity),
    unit_symbol(Irradiance),
    unit_symbol(Pressure),
    unit_symbol(Dimensionless),
  ]
  assert_eq(symbols.length(), 15)
  assert_eq(symbols[0], "mmol N m⁻³")
  assert_eq(symbols[14], "-")
  assert_true(check_unit_compatibility(ConcentrationN, ConcentrationN))
  assert_true(check_unit_compatibility(ConcentrationN, ConcentrationP) == false)
}

///|
test "oceanographic unit converter handles physical transforms" {
  let _converter = UnitConverter::new()
  let chlorophyll = convert_mmol_n_m3_to_mg_chl_m3(2.0, 6.625, 0.03)
  assert_true(chlorophyll > 0.0)
  assert_eq(convert_mmol_n_m3_to_mg_chl_m3(0.0, 6.625, 0.03), 0.0)
  assert_eq(convert_mmol_n_m3_to_mg_chl_m3(-1.0, 6.625, 0.03), 0.0)

  let co2 = convert_mmol_c_m3_to_uatm_co2(12.0, 15.0, 35.0)
  assert_true(co2 > 0.0)
  assert_eq(convert_mmol_c_m3_to_uatm_co2(10.0, 15.0, 2000.0), 400.0)

  let depth = convert_dbar_to_depth_m(100.0, 45.0)
  assert_true(depth > 95.0 && depth < 105.0)
  assert_eq(convert_celsius_to_kelvin(0.0), 273.15)
  assert_eq(convert_kelvin_to_celsius(273.15), 0.0)
  assert_eq(convert_per_day_to_per_hour(24.0), 1.0)
  assert_eq(convert_per_hour_to_per_day(1.0), 24.0)
}
