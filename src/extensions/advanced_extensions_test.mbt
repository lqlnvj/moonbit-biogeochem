// Unit tests for advection and ensemble kalman filter

///|
test "1d vertical advection diffusion step" {
  let conc = [10.0, 5.0, 2.0, 1.0, 0.5]
  let next_c = solve_advection_diffusion_step(conc, 10.0, 1.0, 5.0, 0.1)
  inspect(next_c.length(), content="5")
}

///|
test "ensemble kalman filter assimilation" {
  let v1 = @types.StateVariable::new(
    "N",
    "Nutrient",
    ConcentrationN,
    10.0,
    0.0,
    100.0,
  )
  let state = @types.StateVector::new([v1])
  let enkf = EnsembleFilterState::create(state, 5)
  let updated_enkf = enkf.assimilate_observation("N", 15.0, 0.1).unwrap()
  inspect(updated_enkf.ensemble_size, content="5")
}
