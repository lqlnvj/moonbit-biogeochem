// Ocean Water Column Oxygen Depletion & Hypoxia Model

///|
pub fn create_oxygen_depletion_model(
  init_do : Double,
  init_bod : Double,
) -> @core.BoxModel {
  let var_do = @types.StateVariable::new(
    "DO",
    "Dissolved Oxygen",
    ConcentrationO,
    init_do,
    0.0,
    500.0,
  )
  let var_bod = @types.StateVariable::new(
    "BOD",
    "Biochemical Oxygen Demand",
    ConcentrationO,
    init_bod,
    0.0,
    500.0,
  )

  let state = @types.StateVector::new([var_do, var_bod])

  let params = @types.ParameterMap::from_array([
    @types.ModelParameter::new(
      "k_bod",
      "BOD Decay Rate",
      0.15,
      RatePerDay,
      0.01,
      1.0,
      "Organic matter BOD oxidation rate",
    ),
    @types.ModelParameter::new(
      "wind_speed",
      "Surface Wind Speed",
      7.5,
      Velocity,
      0.0,
      25.0,
      "Surface 10m wind speed in m/s",
    ),
    @types.ModelParameter::new(
      "benthic_sod",
      "Sediment Oxygen Demand",
      10.0,
      Flux,
      0.0,
      100.0,
      "Sediment oxygen demand mmol/m^2/day",
    ),
  ])

  let config = @core.BoxModelConfig::new(
    "Oxygen_Hypoxia", "1.0.0", 1.0e6, 20.0, state, params,
  )

  let evaluator = @core.DerivativeEvaluator::new(fn(_t, y, env, p) {
    let do_conc = y[0]
    let bod = y[1]

    let k_bod = p.get("k_bod").unwrap()
    let wind = p.get("wind_speed").unwrap()
    let sod = p.get("benthic_sod").unwrap()

    let temp_factor = @core.q10_temperature_factor(env.temperature, 20.0, 1.047)

    // Saturation DO concentration & Air-Sea gas exchange
    let do_sat = @core.o2_solubility_saturation(env.temperature, env.salinity)
    let kw = @core.wanninkhof_piston_velocity(wind, env.temperature, "O2")
    let reaeration_flux = @core.air_sea_gas_flux(
      kw,
      config.box_depth_m,
      do_conc,
      do_sat,
    )

    // BOD decay consumes DO
    let bod_decay = k_bod * temp_factor * bod
    let benthic_decay = sod / config.box_depth_m

    // dDO/dt = Reaeration - BOD Decay - Benthic SOD
    let d_do = reaeration_flux - bod_decay - benthic_decay
    // dBOD/dt = - BOD Decay
    let d_bod = -bod_decay

    [d_do, d_bod]
  })

  @core.BoxModel::new(config, evaluator)
}
