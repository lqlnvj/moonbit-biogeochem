// Unit tests for src/extensions module

test "water column 1d initialization and diffusion" {
  let grid = WaterColumn1D::create(5, 50.0, [10.0, 0.5])
  inspect(grid.num_layers, content="5")
  let diff = grid.compute_vertical_diffusion(0)
  inspect(diff.length(), content="5")
}

test "sediment box benthic flux computation" {
  let sed = SedimentBox::default()
  let (n_flux, o2_flux) = sed.compute_benthic_fluxes(20.0)
  assert_true(n_flux > 0.0)
  assert_true(o2_flux > 0.0)
}

test "nudge data assimilation" {
  let v1 = @types.StateVariable::new("N", "Nutrient", ConcentrationN, 10.0, 0.0, 100.0)
  let state = @types.StateVector::new([v1])
  let obs = ObservationPoint::new(1.0, "N", 15.0, 0.1)
  let updated = apply_nudge_assimilation(state, 1.0, [obs], 1.0).unwrap()
  let new_val = updated.get("N").unwrap()
  assert_true(new_val > 10.0 && new_val < 15.0)
}

test "declarative model builder" {
  let v1 = @types.StateVariable::new("N", "Nutrient", ConcentrationN, 10.0, 0.0, 100.0)
  let p1 = @types.ModelParameter::new("k", "Decay", 0.1, RatePerDay, 0.0, 1.0, "Decay")
  let b = ModelBuilder::create("custom_model").add_variable(v1).add_parameter(p1)
  let model = b.build(fn(_t, y, _env, _p) { [ -y[0] * 0.1 ] })
  inspect(model.config.name, content="custom_model")
}
