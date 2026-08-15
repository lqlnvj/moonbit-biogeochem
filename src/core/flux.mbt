// Ocean Biogeochemical Kinetics and Reaction Flux Formulations

///|
pub fn michaelis_menten(substrate_conc : Double, half_sat_k : Double) -> Double {
  if substrate_conc <= 0.0 {
    0.0
  } else {
    substrate_conc / (substrate_conc + half_sat_k)
  }
}

///|
pub fn steele_light_limitation(par : Double, opt_par : Double) -> Double {
  if par <= 0.0 || opt_par <= 0.0 {
    0.0
  } else {
    let ratio = par / opt_par
    ratio * @math.exp(1.0 - ratio)
  }
}

///|
pub fn ivlev_grazing(
  phyto_conc : Double,
  ivlev_lambda : Double,
  threshold_p0 : Double,
) -> Double {
  let p_eff = phyto_conc - threshold_p0
  if p_eff <= 0.0 {
    0.0
  } else {
    1.0 - @math.exp(-ivlev_lambda * p_eff)
  }
}

///|
pub fn q10_temperature_factor(
  temperature_c : Double,
  ref_temp_c : Double,
  q10 : Double,
) -> Double {
  let delta_t = (temperature_c - ref_temp_c) / 10.0
  @math.pow(q10, delta_t)
}

///|
pub fn holling_type2(
  prey_conc : Double,
  half_sat : Double,
  max_rate : Double,
) -> Double {
  if prey_conc <= 0.0 {
    0.0
  } else {
    max_rate * prey_conc / (prey_conc + half_sat)
  }
}

///|
pub fn holling_type3(
  prey_conc : Double,
  half_sat : Double,
  max_rate : Double,
) -> Double {
  if prey_conc <= 0.0 {
    0.0
  } else {
    let sq = prey_conc * prey_conc
    let ks = half_sat * half_sat
    max_rate * sq / (sq + ks)
  }
}

///|
pub fn quadratic_mortality(biomass : Double, mortality_rate : Double) -> Double {
  if biomass <= 0.0 {
    0.0
  } else {
    mortality_rate * biomass * biomass
  }
}

///|
pub(all) struct FluxDescriptor {
  id : String
  source_var : String
  target_var : String
  rate_value : Double
  unit : @types.UnitCategory
} derive(Debug)

///|
pub fn FluxDescriptor::new(
  id : String,
  source : String,
  target : String,
  rate : Double,
  unit : @types.UnitCategory,
) -> FluxDescriptor {
  { id, source_var: source, target_var: target, rate_value: rate, unit }
}
