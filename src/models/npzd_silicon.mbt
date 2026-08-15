// Dual-Phytoplankton Diatom-SmallPhyto Silicon Competition Ecosystem Model

///|
pub fn create_npzd_silicon_model(
  init_n : Double,
  init_si : Double,
  init_p_small : Double,
  init_diatom : Double,
  init_z : Double,
  init_d : Double,
) -> @core.BoxModel {
  let v_n = @types.StateVariable::new(
    "N",
    "Nutrient Nitrogen",
    ConcentrationN,
    init_n,
    0.0,
    100.0,
  )
  let v_si = @types.StateVariable::new(
    "Si",
    "Silicate",
    ConcentrationN,
    init_si,
    0.0,
    100.0,
  )
  let v_ps = @types.StateVariable::new(
    "PS",
    "Small Phytoplankton",
    ConcentrationN,
    init_p_small,
    0.0,
    50.0,
  )
  let v_dia = @types.StateVariable::new(
    "DIA",
    "Diatoms",
    ConcentrationN,
    init_diatom,
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

  let state = @types.StateVector::new([v_n, v_si, v_ps, v_dia, v_z, v_d])

  let params = @types.ParameterMap::from_array([
    @types.ModelParameter::new(
      "v_max_ps",
      "Small Phyto Max Growth",
      1.5,
      RatePerDay,
      0.1,
      4.0,
      "Small phyto growth rate",
    ),
    @types.ModelParameter::new(
      "v_max_dia",
      "Diatom Max Growth",
      2.5,
      RatePerDay,
      0.1,
      5.0,
      "Diatom max growth rate",
    ),
    @types.ModelParameter::new(
      "k_n_ps",
      "Small Phyto Half Sat N",
      0.5,
      ConcentrationN,
      0.05,
      3.0,
      "Small phyto half sat N",
    ),
    @types.ModelParameter::new(
      "k_n_dia",
      "Diatom Half Sat N",
      1.5,
      ConcentrationN,
      0.1,
      5.0,
      "Diatom half sat N",
    ),
    @types.ModelParameter::new(
      "k_si_dia",
      "Diatom Half Sat Si",
      2.0,
      ConcentrationN,
      0.1,
      10.0,
      "Diatom half sat Si",
    ),
    @types.ModelParameter::new(
      "g_max",
      "Zooplankton Grazing",
      1.2,
      RatePerDay,
      0.1,
      3.0,
      "Max zooplankton grazing",
    ),
    @types.ModelParameter::new(
      "si_n_ratio",
      "Diatom Si:N Ratio",
      1.0,
      Dimensionless,
      0.2,
      2.0,
      "Stoichiometric Si:N ratio for diatoms",
    ),
  ])

  let config = @core.BoxModelConfig::new(
    "NPZD_Silicon_Diatom", "1.0.0", 1.0e6, 40.0, state, params,
  )

  let evaluator = @core.DerivativeEvaluator::new(fn(_t, y, env, p) {
    let n = y[0]
    let si = y[1]
    let ps = y[2]
    let dia = y[3]
    let z = y[4]
    let d = y[5]

    let v_ps = p.get("v_max_ps").unwrap()
    let v_dia = p.get("v_max_dia").unwrap()
    let kn_ps = p.get("k_n_ps").unwrap()
    let kn_dia = p.get("k_n_dia").unwrap()
    let ksi_dia = p.get("k_si_dia").unwrap()
    let g_max = p.get("g_max").unwrap()
    let si_n = p.get("si_n_ratio").unwrap()

    let temp_f = @core.q10_temperature_factor(env.temperature, 15.0, 2.0)
    let light_lim = @core.steele_light_limitation(env.surface_par, 120.0)

    // Small Phyto limited only by N
    let prod_ps = v_ps *
      temp_f *
      light_lim *
      @core.michaelis_menten(n, kn_ps) *
      ps

    // Diatoms dual-limited by N and Si (Liebig minimum)
    let lim_n = @core.michaelis_menten(n, kn_dia)
    let lim_si = @core.michaelis_menten(si, ksi_dia)
    let lim_diatom = @core.liebig_minimum_limitation([lim_n, lim_si])
    let prod_dia = v_dia * temp_f * light_lim * lim_diatom * dia

    let grazing_ps = g_max * 0.5 * @core.michaelis_menten(ps, 1.0) * z
    let grazing_dia = g_max * 0.5 * @core.michaelis_menten(dia, 1.0) * z

    let dn = -(prod_ps + prod_dia) + 0.1 * d
    let dsi = -prod_dia * si_n + 0.05 * d * si_n
    let dps = prod_ps - grazing_ps - 0.05 * ps
    let ddia = prod_dia - grazing_dia - 0.05 * dia
    let dz = 0.75 * (grazing_ps + grazing_dia) - 0.1 * z * z
    let dd = 0.05 * ps +
      0.05 * dia +
      0.1 * z * z +
      0.25 * (grazing_ps + grazing_dia) -
      0.1 * d

    [dn, dsi, dps, ddia, dz, dd]
  })

  @core.BoxModel::new(config, evaluator)
}
