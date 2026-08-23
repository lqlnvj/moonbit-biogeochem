///|
test "scenario validation reports invalid integration settings" {
  let model = @models.create_npzd_model(15.0, 0.5, 0.1, 0.2)
  let report = validate_model_scenario(model, 10.0, 0.0)
  assert_true(!report.valid)
  assert_true(report.issues.length() > 0)
}

///|
test "state validation reports negative concentration values" {
  let state = @types.StateVector::new([
    {
      id: "N",
      name: "Nutrient",
      unit: ConcentrationN,
      value: -1.0,
      min_val: 0.0,
      max_val: 100.0,
    },
  ])
  let report = validate_state_vector(state)
  assert_true(!report.valid)
}

///|
test "parameter validation reports an out-of-bound value" {
  let params = @types.ParameterMap::from_array([
    @types.ModelParameter::new(
      "v_max",
      "Maximum growth",
      4.0,
      RatePerDay,
      0.5,
      3.0,
      "Growth rate",
    ),
  ])
  let report = validate_parameter_map(params)
  assert_true(!report.valid)
}

///|
test "valid model scenario produces no errors" {
  let model = @models.create_npzd_model(15.0, 0.5, 0.1, 0.2)
  let report = validate_model_scenario(model, 10.0, 0.5)
  assert_true(report.valid)
  assert_eq(report.issues.length(), 0)
}
