// High-Nutrient Low-Chlorophyll (HNLC) Iron Limitation Ocean Box Model

///|
pub fn create_npzd_iron_model(
  init_n : Double,
  init_fe : Double,
  init_p : Double,
  init_z : Double,
  init_d : Double,
) -> @core.BoxModel {
  let v_n = @types.StateVariable::new(
    "N",
    "Nitrate Nutrient",
    ConcentrationN,
    init_n,
    0.0,
    100.0,
  )
  let v_fe = @types.StateVariable::new(
    "Fe",
    "Dissolved Iron",
    ConcentrationN,
    init_fe,
    0.0,
    10.0,
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

  let state = @types.StateVector::new([v_n, v_fe, v_p, v_z, v_d])

  let params = @types.ParameterMap::from_array([
    @types.ModelParameter::new(
      "v_max",
      "Max Phyto Growth",
      2.0,
      RatePerDay,
      0.1,
      5.0,
      "Max phytoplankton growth rate",
    ),
    @types.ModelParameter::new(
      "k_n",
      "Nitrate Half Sat",
      1.0,
      ConcentrationN,
      0.1,
      5.0,
      "Nitrate half sat",
    ),
    @types.ModelParameter::new(
      "k_fe",
      "Iron Half Sat",
      0.1,
      ConcentrationN,
      0.01,
      1.0,
      "Iron half sat constant in nmol/L",
    ),
    @types.ModelParameter::new(
      "fe_n_ratio",
      "Phyto Fe:N Ratio",
      0.005,
      Dimensionless,
      0.001,
      0.02,
      "Stoichiometric Fe:N ratio",
    ),
    @types.ModelParameter::new(
      "dust_flux",
      "Atmospheric Dust Fe Input",
      0.01,
      Flux,
      0.0,
      0.1,
      "Atmospheric iron deposition flux",
    ),
  ])

  let config = @core.BoxModelConfig::new(
    "HNLC_Iron_NPZD", "1.0.0", 1.0e6, 50.0, state, params,
  )

  let evaluator = @core.DerivativeEvaluator::new(fn(_t, y, env, p) {
    let n = y[0]
    let fe = y[1]
    let p_conc = y[2]
    let z = y[3]
    let d = y[4]

    let v_max = p.get("v_max").unwrap()
    let k_n = p.get("k_n").unwrap()
    let k_fe = p.get("k_fe").unwrap()
    let fe_n = p.get("fe_n_ratio").unwrap()
    let dust = p.get("dust_flux").unwrap()

    let temp_f = @core.q10_temperature_factor(env.temperature, 15.0, 2.0)
    let light_lim = @core.steele_light_limitation(env.surface_par, 100.0)

    // Co-limitation by Nitrate and Iron (Liebig minimum)
    let lim_n = @core.michaelis_menten(n, k_n)
    let lim_fe = @core.michaelis_menten(fe, k_fe)
    let co_lim = @core.liebig_minimum_limitation([lim_n, lim_fe])

    let prim_prod = v_max * temp_f * light_lim * co_lim * p_conc
    let grazing = 1.0 * temp_f * @core.michaelis_menten(p_conc, 1.0) * z

    let dn = -prim_prod + 0.1 * d
    let dfe = dust / config.box_depth_m - prim_prod * fe_n + 0.1 * d * fe_n
    let dp = prim_prod - grazing - 0.05 * p_conc
    let dz = 0.75 * grazing - 0.2 * z * z
    let dd = 0.05 * p_conc + 0.2 * z * z + 0.25 * grazing - 0.1 * d

    [dn, dfe, dp, dz, dd]
  })

  @core.BoxModel::new(config, evaluator)
}
