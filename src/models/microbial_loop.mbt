// Ocean Microbial Loop Compartment Model (DOM, Bacteria, Protozoa)

///|
pub fn create_microbial_loop_model(
  init_dom : Double,
  init_bact : Double,
  init_prot : Double,
  init_din : Double,
) -> @core.BoxModel {
  let v_dom = @types.StateVariable::new(
    "DOM",
    "Dissolved Organic Matter",
    ConcentrationC,
    init_dom,
    0.0,
    500.0,
  )
  let v_bact = @types.StateVariable::new(
    "BACT",
    "Heterotrophic Bacteria",
    ConcentrationC,
    init_bact,
    0.0,
    100.0,
  )
  let v_prot = @types.StateVariable::new(
    "PROT",
    "Protozoa",
    ConcentrationC,
    init_prot,
    0.0,
    50.0,
  )
  let v_din = @types.StateVariable::new(
    "DIN",
    "Dissolved Inorganic Nitrogen",
    ConcentrationN,
    init_din,
    0.0,
    100.0,
  )

  let state = @types.StateVector::new([v_dom, v_bact, v_prot, v_din])

  let params = @types.ParameterMap::from_array([
    @types.ModelParameter::new(
      "mu_bact",
      "Bacteria Max Growth",
      2.0,
      RatePerDay,
      0.1,
      6.0,
      "Bacteria max growth rate on DOM",
    ),
    @types.ModelParameter::new(
      "k_dom",
      "DOM Half Saturation",
      10.0,
      ConcentrationC,
      1.0,
      50.0,
      "DOM half sat constant",
    ),
    @types.ModelParameter::new(
      "bge",
      "Bacterial Growth Efficiency",
      0.30,
      Dimensionless,
      0.05,
      0.6,
      "Fraction of consumed DOM turned into biomass",
    ),
    @types.ModelParameter::new(
      "g_prot",
      "Protozoa Max Grazing",
      1.5,
      RatePerDay,
      0.1,
      4.0,
      "Protozoa grazing rate on bacteria",
    ),
    @types.ModelParameter::new(
      "k_bact",
      "Bacteria Half Sat Grazing",
      2.0,
      ConcentrationC,
      0.1,
      10.0,
      "Bacteria half sat for protozoa",
    ),
  ])

  let config = @core.BoxModelConfig::new(
    "Microbial_Loop", "1.0.0", 1.0e6, 20.0, state, params,
  )

  let evaluator = @core.DerivativeEvaluator::new(fn(_t, y, env, p) {
    let dom = y[0]
    let bact = y[1]
    let prot = y[2]
    let _din = y[3]

    let mu_b = p.get("mu_bact").unwrap()
    let k_dom = p.get("k_dom").unwrap()
    let bge = p.get("bge").unwrap()
    let g_pr = p.get("g_prot").unwrap()
    let k_b = p.get("k_bact").unwrap()

    let temp_f = @core.q10_temperature_factor(env.temperature, 20.0, 2.1)

    let dom_uptake = mu_b * temp_f * @core.michaelis_menten(dom, k_dom) * bact
    let bact_growth = dom_uptake * bge
    let bact_respiration = dom_uptake * (1.0 - bge)

    let prot_grazing = g_pr * temp_f * @core.michaelis_menten(bact, k_b) * prot
    let prot_growth = 0.6 * prot_grazing
    let prot_excretion = 0.4 * prot_grazing

    let d_dom = -dom_uptake + 0.1 * prot_excretion
    let d_bact = bact_growth - prot_grazing - 0.05 * bact
    let d_prot = prot_growth - 0.1 * prot * prot
    let d_din = (bact_respiration + prot_excretion * 0.9 + 0.1 * prot * prot) *
      (16.0 / 106.0)

    [d_dom, d_bact, d_prot, d_din]
  })

  @core.BoxModel::new(config, evaluator)
}
