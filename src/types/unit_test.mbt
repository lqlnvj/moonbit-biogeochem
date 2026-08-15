// Unit tests for src/types module

test "physical quantity creation and scaling" {
  let q = PhysicalQuantity::new(10.0, ConcentrationN, "DIN")
  inspect(q.value, content="10")
  let scaled = scale_quantity(q, 2.5)
  inspect(scaled.value, content="25")
}

test "state variable clamping and bounds" {
  let v = StateVariable::new("P", "Phytoplankton", ConcentrationN, 5.0, 0.0, 10.0)
  inspect(v.value, content="5")
  let v_clamped = StateVariable::new("P", "Phytoplankton", ConcentrationN, 15.0, 0.0, 10.0)
  inspect(v_clamped.value, content="10")
}

test "state vector indexing and updates" {
  let v1 = StateVariable::new("N", "Nutrient", ConcentrationN, 2.0, 0.0, 50.0)
  let v2 = StateVariable::new("P", "Phytoplankton", ConcentrationN, 0.5, 0.0, 20.0)
  let vec = StateVector::new([v1, v2])
  inspect(vec.dimension(), content="2")
  let val = vec.get("N").unwrap()
  inspect(val, content="2")

  let updated_vec = vec.set("P", 1.2).unwrap()
  let p_val = updated_vec.get("P").unwrap()
  inspect(p_val, content="1.2")
}

test "parameter map lookup and bounds" {
  let p1 = ModelParameter::new("mu_max", "Max Growth Rate", 1.5, RatePerDay, 0.1, 3.0, "Max phytoplankton growth rate")
  let map = ParameterMap::from_array([p1])
  let val = map.get("mu_max").unwrap()
  inspect(val, content="1.5")
}

test "seasonal environment forcing" {
  let env = EnvironmentForcing::seasonal_forcing(180.0, 45.0)
  inspect(env.time_day, content="180")
  assert_true(env.temperature > 10.0)
}
