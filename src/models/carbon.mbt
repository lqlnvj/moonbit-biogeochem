// Simplified Ocean Carbonate Chemistry & Air-Sea CO2 Flux

pub fn estimate_pco2_microatm(dic_mmol_m3 : Double, ta_mmol_m3 : Double, temp_c : Double) -> Double {
  let ratio = dic_mmol_m3 / (ta_mmol_m3 + 1.0e-6)
  let base_pco2 = 400.0 * @math.pow(ratio / 0.85, 2.2)
  let temp_factor = @math.exp(0.042 * (temp_c - 15.0))
  base_pco2 * temp_factor
}

pub fn create_ocean_carbon_model(
  init_dic : Double,
  init_ta : Double
) -> @core.BoxModel {
  let var_dic = @types.StateVariable::new("DIC", "Dissolved Inorganic Carbon", ConcentrationC, init_dic, 1500.0, 2500.0)
  let var_ta = @types.StateVariable::new("TA", "Total Alkalinity", ConcentrationC, init_ta, 1500.0, 2500.0)

  let state = @types.StateVector::new([var_dic, var_ta])

  let params = @types.ParameterMap::from_array([
    @types.ModelParameter::new("pco2_atm", "Atmospheric pCO2", 420.0, Dimensionless, 200.0, 800.0, "Atmospheric pCO2 in uatm"),
    @types.ModelParameter::new("wind_speed", "Surface Wind Speed", 8.0, Velocity, 0.0, 25.0, "Surface wind speed in m/s"),
    @types.ModelParameter::new("k_solubility", "CO2 Solubility K0", 0.035, Dimensionless, 0.01, 0.1, "CO2 Henry's law constant mmol/m^3/uatm")
  ])

  let config = @core.BoxModelConfig::new("Ocean_Carbonate", "1.0.0", 1.0e6, 30.0, state, params)

  let evaluator = @core.DerivativeEvaluator::new(fn(_t, y, env, p) {
    let dic = y[0]
    let ta = y[1]

    let pco2_atm = p.get("pco2_atm").unwrap()
    let wind = p.get("wind_speed").unwrap()
    let k0 = p.get("k_solubility").unwrap()

    let kw = @core.wanninkhof_piston_velocity(wind, env.temperature, "CO2")
    let pco2_sw = estimate_pco2_microatm(dic, ta, env.temperature)

    // Air-sea CO2 flux F = kw * K0 * (pCO2_atm - pCO2_sw) / MLD
    let co2_flux = kw * k0 * (pco2_atm - pco2_sw) / config.box_depth_m

    // dDIC/dt = Air-Sea Flux
    let d_dic = co2_flux
    let d_ta = 0.0 // TA conserved without calcification

    [ d_dic, d_ta ]
  })

  @core.BoxModel::new(config, evaluator)
}
