// 6-Compartment Extended NPZD+D (Fast & Slow Detritus) Model

pub fn create_npzdd_model(
  init_n : Double,
  init_p : Double,
  init_z : Double,
  init_sd : Double,
  init_fd : Double,
  init_ben : Double
) -> @core.BoxModel {
  let var_n = @types.StateVariable::new("N", "Nutrient", ConcentrationN, init_n, 0.0, 100.0)
  let var_p = @types.StateVariable::new("P", "Phytoplankton", ConcentrationN, init_p, 0.0, 50.0)
  let var_z = @types.StateVariable::new("Z", "Zooplankton", ConcentrationN, init_z, 0.0, 50.0)
  let var_sd = @types.StateVariable::new("SD", "Slow Detritus", ConcentrationN, init_sd, 0.0, 100.0)
  let var_fd = @types.StateVariable::new("FD", "Fast Detritus", ConcentrationN, init_fd, 0.0, 100.0)
  let var_ben = @types.StateVariable::new("BEN", "Benthic Pool", ConcentrationN, init_ben, 0.0, 500.0)
  
  let state = @types.StateVector::new([var_n, var_p, var_z, var_sd, var_fd, var_ben])
  
  let params = @types.ParameterMap::from_array([
    @types.ModelParameter::new("v_max", "Max Growth Rate", 1.8, RatePerDay, 0.1, 4.0, "Phytoplankton growth rate"),
    @types.ModelParameter::new("k_n", "Nutrient Half Sat", 0.8, ConcentrationN, 0.1, 5.0, "Half-saturation constant N"),
    @types.ModelParameter::new("g_max", "Max Grazing Rate", 1.2, RatePerDay, 0.1, 3.0, "Zooplankton max grazing"),
    @types.ModelParameter::new("k_z", "Grazing Half Sat", 0.9, ConcentrationN, 0.1, 5.0, "Grazing half sat P"),
    @types.ModelParameter::new("beta", "Assimilation Efficiency", 0.70, Dimensionless, 0.1, 1.0, "Assimilated fraction"),
    @types.ModelParameter::new("f_sd", "Fraction to Slow Detritus", 0.6, Dimensionless, 0.0, 1.0, "Unassimilated fraction to SD"),
    @types.ModelParameter::new("m_p", "Phyto Mortality Rate", 0.04, RatePerDay, 0.001, 0.2, "Linear mortality P"),
    @types.ModelParameter::new("m_z", "Zoo Mortality Rate", 0.15, RatePerDay, 0.01, 0.5, "Quadratic mortality Z"),
    @types.ModelParameter::new("r_sd", "Slow Detritus Remin Rate", 0.08, RatePerDay, 0.01, 0.3, "Remineralization SD to N"),
    @types.ModelParameter::new("r_fd", "Fast Detritus Remin Rate", 0.20, RatePerDay, 0.01, 0.5, "Remineralization FD to N"),
    @types.ModelParameter::new("w_sd", "Slow Detritus Sinking", 2.0, Velocity, 0.0, 10.0, "Slow sinking velocity m/day"),
    @types.ModelParameter::new("w_fd", "Fast Detritus Sinking", 20.0, Velocity, 1.0, 100.0, "Fast sinking velocity m/day"),
    @types.ModelParameter::new("r_ben", "Benthic Flux Return Rate", 0.02, RatePerDay, 0.001, 0.1, "Benthic flux recycling to N")
  ])
  
  let config = @core.BoxModelConfig::new("NPZDD_Extended", "1.0.0", 1.0e6, 40.0, state, params)
  
  let evaluator = @core.DerivativeEvaluator::new(fn(_t, y, env, p) {
    let n = y[0]
    let p_conc = y[1]
    let z = y[2]
    let sd = y[3]
    let fd = y[4]
    let ben = y[5]
    
    let v_max = p.get("v_max").unwrap()
    let k_n = p.get("k_n").unwrap()
    let g_max = p.get("g_max").unwrap()
    let k_z = p.get("k_z").unwrap()
    let beta = p.get("beta").unwrap()
    let f_sd = p.get("f_sd").unwrap()
    let m_p = p.get("m_p").unwrap()
    let m_z = p.get("m_z").unwrap()
    let r_sd = p.get("r_sd").unwrap()
    let r_fd = p.get("r_fd").unwrap()
    let w_sd = p.get("w_sd").unwrap()
    let w_fd = p.get("w_fd").unwrap()
    let r_ben = p.get("r_ben").unwrap()
    
    let temp_f = @core.q10_temperature_factor(env.temperature, 15.0, 2.0)
    let light_lim = @core.steele_light_limitation(env.surface_par, 120.0)
    let prim_prod = v_max * temp_f * light_lim * @core.michaelis_menten(n, k_n) * p_conc
    let grazing = g_max * temp_f * @core.michaelis_menten(p_conc, k_z) * z
    
    let p_mort = m_p * p_conc
    let z_mort = @core.quadratic_mortality(z, m_z)
    let unassimilated = (1.0 - beta) * grazing
    
    let to_sd = unassimilated * f_sd + p_mort
    let to_fd = unassimilated * (1.0 - f_sd) + z_mort
    
    let remin_sd = r_sd * temp_f * sd
    let remin_fd = r_fd * temp_f * fd
    let sink_sd = @core.sinking_particle_flux(w_sd, sd, config.box_depth_m)
    let sink_fd = @core.sinking_particle_flux(w_fd, fd, config.box_depth_m)
    let ben_return = r_ben * temp_f * ben
    
    let dn = -prim_prod + remin_sd + remin_fd + ben_return
    let dp = prim_prod - grazing - p_mort
    let dz = beta * grazing - z_mort
    let dsd = to_sd - remin_sd - sink_sd
    let dfd = to_fd - remin_fd - sink_fd
    let dben = (sink_sd + sink_fd) * config.box_depth_m - ben_return
    
    [ dn, dp, dz, dsd, dfd, dben ]
  })
  
  @core.BoxModel::new(config, evaluator)
}
