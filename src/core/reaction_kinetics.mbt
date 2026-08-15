// Advanced Ecological Reaction Kinetics & Acclimation Models

///|
pub fn liebig_minimum_limitation(limitation_factors : Array[Double]) -> Double {
  if limitation_factors.length() == 0 {
    1.0
  } else {
    let mut min_lim = limitation_factors[0]
    for i = 1; i < limitation_factors.length(); i = i + 1 {
      if limitation_factors[i] < min_lim {
        min_lim = limitation_factors[i]
      }
    }
    if min_lim < 0.0 {
      0.0
    } else {
      min_lim
    }
  }
}

///|
pub fn droop_cell_quota_limitation(
  quota_q : Double,
  min_quota_q0 : Double,
) -> Double {
  // Droop (1968) cell-quota nutrient limitation model f(Q) = 1 - Q0 / Q
  if quota_q <= min_quota_q0 {
    0.0
  } else {
    1.0 - min_quota_q0 / quota_q
  }
}

///|
pub fn geider_chl_c_ratio(
  par : Double,
  temp_c : Double,
  nutrient_limitation : Double,
  max_chl_c : Double,
  ref_alpha : Double,
) -> Double {
  // Geider et al. (1998) dynamic Chl:C ratio adjustment to ambient light and nutrient status
  if par <= 0.0 {
    max_chl_c
  } else {
    let temp_f = q10_temperature_factor(temp_c, 15.0, 2.0)
    let denom = 1.0 +
      ref_alpha *
      par *
      max_chl_c /
      (2.0 * temp_f * nutrient_limitation + 1.0e-6)
    max_chl_c / denom
  }
}

///|
pub fn temperature_arrhenius_factor(
  temp_k : Double,
  ref_temp_k : Double,
  activation_energy_j_mol : Double,
) -> Double {
  // Arrhenius equation for metabolic rate temperature dependence
  let r_gas = 8.3144626 // Universal gas constant J / (mol K)
  let exponent = activation_energy_j_mol /
    r_gas *
    (1.0 / ref_temp_k - 1.0 / temp_k)
  @math.exp(exponent)
}
