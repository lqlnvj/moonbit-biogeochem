// Fully Coupled NPZD - Oxygen - Carbonate System Ocean Box Model

///|
pub fn create_coupled_carbon_npzd_model(
  init_n : Double,
  init_p : Double,
  init_z : Double,
  init_d : Double,
  init_do : Double,
  init_dic : Double,
  init_ta : Double,
) -> @core.BoxModel {
  let v_n = @types.StateVariable::new(
    "N",
    "Nutrient",
    ConcentrationN,
    init_n,
    0.0,
    100.0,
  )
  let v_p = @types.StateVariable::new(
    "P",
    "Phytoplankton",
    ConcentrationN,
    init_p,
    0.0,
    50.0,
  )
  let v_z = @types.StateVariable::new(
    "Z",
    "Zooplankton",
    ConcentrationN,
    init_z,
    0.0,
    50.0,
  )
  let v_d = @types.StateVariable::new(
    "D",
    "Detritus",
    ConcentrationN,
    init_d,
    0.0,
    100.0,
  )
  let v_do = @types.StateVariable::new(
    "DO",
    "Dissolved Oxygen",
    ConcentrationO,
    init_do,
    0.0,
    600.0,
  )
  let v_dic = @types.StateVariable::new(
    "DIC",
    "Dissolved Inorganic Carbon",
    ConcentrationC,
    init_dic,
    1000.0,
    3000.0,
  )
  let v_ta = @types.StateVariable::new(
    "TA",
    "Total Alkalinity",
    ConcentrationC,
    init_ta,
    1000.0,
    3000.0,
  )

  let state = @types.StateVector::new([v_n, v_p, v_z, v_d, v_do, v_dic, v_ta])

  let params = @types.ParameterMap::from_array([
    @types.ModelParameter::new(
      "v_max",
      "Max Growth Rate",
      2.0,
      RatePerDay,
      0.1,
      5.0,
      "Phytoplankton growth rate",
    ),
    @types.ModelParameter::new(
      "k_n",
      "Nutrient Half Sat",
      1.0,
      ConcentrationN,
      0.1,
      10.0,
      "Half sat N",
    ),
    @types.ModelParameter::new(
      "g_max",
      "Max Grazing Rate",
      1.0,
      RatePerDay,
      0.1,
      3.0,
      "Zooplankton grazing rate",
    ),
    @types.ModelParameter::new(
      "k_z",
      "Grazing Half Sat",
      1.0,
      ConcentrationN,
      0.1,
      5.0,
      "Grazing half sat P",
    ),
    @types.ModelParameter::new(
      "beta",
      "Assimilation Efficiency",
      0.75,
      Dimensionless,
      0.1,
      1.0,
      "Assimilated fraction",
    ),
    @types.ModelParameter::new(
      "m_p",
      "Phyto Mortality Rate",
      0.05,
      RatePerDay,
      0.001,
      0.5,
      "Phytoplankton mortality",
    ),
    @types.ModelParameter::new(
      "m_z",
      "Zoo Mortality Rate",
      0.2,
      RatePerDay,
      0.01,
      1.0,
      "Zooplankton mortality",
    ),
    @types.ModelParameter::new(
      "r_d",
      "Detritus Remin Rate",
      0.1,
      RatePerDay,
      0.01,
      0.5,
      "Remineralization rate",
    ),
    @types.ModelParameter::new(
      "w_d",
      "Detritus Sinking",
      5.0,
      Velocity,
      0.0,
      50.0,
      "Detritus sinking velocity",
    ),
    @types.ModelParameter::new(
      "wind_speed",
      "Surface Wind Speed",
      7.5,
      Velocity,
      0.0,
      25.0,
      "Wind speed u10",
    ),
    @types.ModelParameter::new(
      "pco2_atm",
      "Atmospheric pCO2",
      420.0,
      Dimensionless,
      200.0,
      800.0,
      "pCO2 atm in uatm",
    ),
    @types.ModelParameter::new(
      "k_solubility",
      "CO2 Solubility",
      0.035,
      Dimensionless,
      0.01,
      0.1,
      "Henry law K0",
    ),
  ])

  let config = @core.BoxModelConfig::new(
    "Coupled_NPZD_Carbon_O2", "1.0.0", 1.0e6, 50.0, state, params,
  )
  let redfield = @core.RedfieldRatio::standard()

  let evaluator = @core.DerivativeEvaluator::new(fn(_t, y, env, p) {
    let n = y[0]
    let p_conc = y[1]
    let z = y[2]
    let d = y[3]
    let do_conc = y[4]
    let dic = y[5]
    let ta = y[6]

    let v_max = p.get("v_max").unwrap()
    let k_n = p.get("k_n").unwrap()
    let g_max = p.get("g_max").unwrap()
    let k_z = p.get("k_z").unwrap()
    let beta = p.get("beta").unwrap()
    let m_p = p.get("m_p").unwrap()
    let m_z = p.get("m_z").unwrap()
    let r_d = p.get("r_d").unwrap()
    let w_d = p.get("w_d").unwrap()
    let wind = p.get("wind_speed").unwrap()
    let pco2_atm = p.get("pco2_atm").unwrap()
    let k0 = p.get("k_solubility").unwrap()

    let temp_f = @core.q10_temperature_factor(env.temperature, 15.0, 2.0)
    let light_lim = @core.steele_light_limitation(env.surface_par, 100.0)
    let prim_prod = v_max *
      temp_f *
      light_lim *
      @core.michaelis_menten(n, k_n) *
      p_conc
    let grazing = g_max * temp_f * @core.michaelis_menten(p_conc, k_z) * z

    let phyto_mort = m_p * p_conc
    let zoo_mort = @core.quadratic_mortality(z, m_z)
    let unassimilated = (1.0 - beta) * grazing
    let remineral = r_d * temp_f * d
    let sinking = @core.sinking_particle_flux(w_d, d, config.box_depth_m)

    // Gas fluxes
    let kw_o2 = @core.wanninkhof_piston_velocity(wind, env.temperature, "O2")
    let do_sat = @core.o2_solubility_saturation(env.temperature, env.salinity)
    let o2_reaeration = @core.air_sea_gas_flux(
      kw_o2,
      config.box_depth_m,
      do_conc,
      do_sat,
    )

    let kw_co2 = @core.wanninkhof_piston_velocity(wind, env.temperature, "CO2")
    let pco2_sw = estimate_pco2_microatm(dic, ta, env.temperature)
    let co2_air_sea = kw_co2 * k0 * (pco2_atm - pco2_sw) / config.box_depth_m

    // Redfield scaling: N -> C (106/16), N -> O2 (138/16)
    let n_to_c = redfield.c_to_n()
    let n_to_o2 = redfield.o2_to_n()

    let dn = -prim_prod + remineral
    let dp = prim_prod - grazing - phyto_mort
    let dz = beta * grazing - zoo_mort
    let dd = phyto_mort + zoo_mort + unassimilated - remineral - sinking

    // Oxygen dynamics: Photosynthesis releases O2, Remineralization & Respiration consumes O2
    let d_do = o2_reaeration + (prim_prod - remineral - zoo_mort) * n_to_o2

    // DIC dynamics: Photosynthesis consumes DIC, Remineralization & Respiration releases DIC, plus Air-sea exchange
    let d_dic = co2_air_sea + (-prim_prod + remineral + zoo_mort) * n_to_c

    // TA dynamics: Nitrate uptake increases alkalinity, remineralization decreases alkalinity
    let d_ta = prim_prod - remineral

    [dn, dp, dz, dd, d_do, d_dic, d_ta]
  })

  @core.BoxModel::new(config, evaluator)
}
