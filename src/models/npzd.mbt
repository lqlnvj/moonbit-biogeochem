// NPZD (Nutrient-Phytoplankton-Zooplankton-Detritus) 4-Compartment Model

///|
pub fn create_npzd_model_with_params(
  params : @types.ParameterMap,
) -> @core.BoxModel {
  let var_n = @types.StateVariable::new(
    "N",
    "Nutrient",
    ConcentrationN,
    15.0,
    0.0,
    100.0,
  )
  let var_p = @types.StateVariable::new(
    "P",
    "Phytoplankton",
    ConcentrationN,
    0.5,
    0.0,
    50.0,
  )
  let var_z = @types.StateVariable::new(
    "Z",
    "Zooplankton",
    ConcentrationN,
    0.1,
    0.0,
    50.0,
  )
  let var_d = @types.StateVariable::new(
    "D",
    "Detritus",
    ConcentrationN,
    0.2,
    0.0,
    100.0,
  )

  let state = @types.StateVector::new([var_n, var_p, var_z, var_d])
  let config = @core.BoxModelConfig::new(
    "NPZD_Standard", "1.0.0", 1.0e6, 50.0, state, params,
  )

  let evaluator = @core.DerivativeEvaluator::new(fn(_t, y, env, p) {
    let n = y[0]
    let p_conc = y[1]
    let z = y[2]
    let d = y[3]

    let v_max = p.get("v_max").unwrap()
    let k_n = p.get("k_n").unwrap()
    let kw = p.get("kw").unwrap()
    let k_p = p.get("k_p").unwrap()
    let g_max = p.get("g_max").unwrap()
    let k_z = p.get("k_z").unwrap()
    let beta = p.get("beta").unwrap()
    let m_p = p.get("m_p").unwrap()
    let m_z = p.get("m_z").unwrap()
    let r_d = p.get("r_d").unwrap()
    let w_d = p.get("w_d").unwrap()

    let temp_factor = @core.q10_temperature_factor(env.temperature, 15.0, 2.0)
    let par_avg = env.par_at_depth(config.box_depth_m * 0.5, kw, k_p, p_conc)
    let light_lim = @core.steele_light_limitation(par_avg, 100.0)
    let nutrient_lim = @core.michaelis_menten(n, k_n)

    let primary_prod = v_max * temp_factor * light_lim * nutrient_lim * p_conc
    let grazing = g_max * temp_factor * @core.michaelis_menten(p_conc, k_z) * z

    let phyto_mort = m_p * p_conc
    let zoo_mort = @core.quadratic_mortality(z, m_z)
    let unassimilated = (1.0 - beta) * grazing

    let remineral = r_d * temp_factor * d
    let sinking = @core.sinking_particle_flux(w_d, d, config.box_depth_m)

    let dn_dt = -primary_prod + remineral
    let dp_dt = primary_prod - grazing - phyto_mort
    let dz_dt = beta * grazing - zoo_mort
    let dd_dt = phyto_mort + zoo_mort + unassimilated - remineral - sinking

    [dn_dt, dp_dt, dz_dt, dd_dt]
  })

  @core.BoxModel::new(config, evaluator)
}

///|
pub fn create_npzd_model(
  init_n : Double,
  init_p : Double,
  init_z : Double,
  init_d : Double,
) -> @core.BoxModel {
  let params = @types.ParameterMap::from_array([
    @types.ModelParameter::new(
      "v_max",
      "Max Phyto Growth Rate",
      2.0,
      RatePerDay,
      0.1,
      5.0,
      "Maximum phytoplankton growth rate at ref temp",
    ),
    @types.ModelParameter::new(
      "k_n",
      "Nutrient Half Saturation",
      1.0,
      ConcentrationN,
      0.1,
      10.0,
      "Half-saturation constant for nutrient uptake",
    ),
    @types.ModelParameter::new(
      "alpha",
      "Initial Slope of P-I Curve",
      0.025,
      RatePerDay,
      0.001,
      0.1,
      "Photosynthetic efficiency",
    ),
    @types.ModelParameter::new(
      "kw",
      "Light Extinction Water",
      0.04,
      RatePerDay,
      0.01,
      0.2,
      "Attenuation coefficient for clear water",
    ),
    @types.ModelParameter::new(
      "k_p",
      "Self-shading Coefficient",
      0.03,
      ConcentrationN,
      0.005,
      0.1,
      "Attenuation coefficient by phytoplankton",
    ),
    @types.ModelParameter::new(
      "g_max",
      "Max Zooplankton Grazing Rate",
      1.0,
      RatePerDay,
      0.1,
      3.0,
      "Maximum zooplankton grazing rate",
    ),
    @types.ModelParameter::new(
      "k_z",
      "Grazing Half Saturation",
      1.0,
      ConcentrationN,
      0.1,
      5.0,
      "Half-saturation constant for grazing",
    ),
    @types.ModelParameter::new(
      "beta",
      "Zooplankton Assimilation Efficiency",
      0.75,
      Dimensionless,
      0.1,
      1.0,
      "Fraction of grazed P assimilated",
    ),
    @types.ModelParameter::new(
      "m_p",
      "Phytoplankton Mortality Rate",
      0.05,
      RatePerDay,
      0.001,
      0.5,
      "Linear phytoplankton mortality",
    ),
    @types.ModelParameter::new(
      "m_z",
      "Zooplankton Quadratic Mortality Rate",
      0.2,
      RatePerDay,
      0.01,
      1.0,
      "Quadratic zooplankton mortality",
    ),
    @types.ModelParameter::new(
      "r_d",
      "Detritus Remineralization Rate",
      0.1,
      RatePerDay,
      0.01,
      0.5,
      "Remineralization rate of detritus to nutrient",
    ),
    @types.ModelParameter::new(
      "w_d",
      "Detritus Sinking Velocity",
      5.0,
      Velocity,
      0.0,
      50.0,
      "Sinking velocity of detritus particles",
    ),
  ])

  let var_n = @types.StateVariable::new(
    "N",
    "Nutrient",
    ConcentrationN,
    init_n,
    0.0,
    100.0,
  )
  let var_p = @types.StateVariable::new(
    "P",
    "Phytoplankton",
    ConcentrationN,
    init_p,
    0.0,
    50.0,
  )
  let var_z = @types.StateVariable::new(
    "Z",
    "Zooplankton",
    ConcentrationN,
    init_z,
    0.0,
    50.0,
  )
  let var_d = @types.StateVariable::new(
    "D",
    "Detritus",
    ConcentrationN,
    init_d,
    0.0,
    100.0,
  )

  let state = @types.StateVector::new([var_n, var_p, var_z, var_d])
  let config = @core.BoxModelConfig::new(
    "NPZD_Standard", "1.0.0", 1.0e6, 50.0, state, params,
  )

  let evaluator = @core.DerivativeEvaluator::new(fn(_t, y, env, p) {
    let n = y[0]
    let p_conc = y[1]
    let z = y[2]
    let d = y[3]

    let v_max = p.get("v_max").unwrap()
    let k_n = p.get("k_n").unwrap()
    let kw = p.get("kw").unwrap()
    let k_p = p.get("k_p").unwrap()
    let g_max = p.get("g_max").unwrap()
    let k_z = p.get("k_z").unwrap()
    let beta = p.get("beta").unwrap()
    let m_p = p.get("m_p").unwrap()
    let m_z = p.get("m_z").unwrap()
    let r_d = p.get("r_d").unwrap()
    let w_d = p.get("w_d").unwrap()

    let temp_factor = @core.q10_temperature_factor(env.temperature, 15.0, 2.0)
    let par_avg = env.par_at_depth(config.box_depth_m * 0.5, kw, k_p, p_conc)
    let light_lim = @core.steele_light_limitation(par_avg, 100.0)
    let nutrient_lim = @core.michaelis_menten(n, k_n)

    let primary_prod = v_max * temp_factor * light_lim * nutrient_lim * p_conc
    let grazing = g_max * temp_factor * @core.michaelis_menten(p_conc, k_z) * z

    let phyto_mort = m_p * p_conc
    let zoo_mort = @core.quadratic_mortality(z, m_z)
    let unassimilated = (1.0 - beta) * grazing

    let remineral = r_d * temp_factor * d
    let sinking = @core.sinking_particle_flux(w_d, d, config.box_depth_m)

    let dn_dt = -primary_prod + remineral
    let dp_dt = primary_prod - grazing - phyto_mort
    let dz_dt = beta * grazing - zoo_mort
    let dd_dt = phyto_mort + zoo_mort + unassimilated - remineral - sinking

    [dn_dt, dp_dt, dz_dt, dd_dt]
  })

  @core.BoxModel::new(config, evaluator)
}

///|
pub fn run_npzd_simulation(
  model : @core.BoxModel,
  days : Double,
  dt : Double,
) -> Result[@solver.Trajectory, String] {
  let env_fn = fn(t) { @types.EnvironmentForcing::seasonal_forcing(t, 45.0) }
  @solver.solve_rk4(model, days, dt, env_fn)
}
