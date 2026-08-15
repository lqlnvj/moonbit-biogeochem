// Surface and Bottom Boundary Conditions (Air-Sea Gas Exchange and Benthic Fluxes)

///|
pub fn wanninkhof_piston_velocity(
  wind_speed_10m : Double,
  temperature_c : Double,
  gas_type : String,
) -> Double {
  let sc = match gas_type {
    "O2" =>
      1953.4 -
      128.0 * temperature_c +
      3.9918 * temperature_c * temperature_c -
      0.05009 * temperature_c * temperature_c * temperature_c
    "CO2" =>
      2116.8 -
      136.25 * temperature_c +
      4.7353 * temperature_c * temperature_c -
      0.092307 * temperature_c * temperature_c * temperature_c
    _ => 660.0
  }
  let kw_cm_hr = 0.251 *
    wind_speed_10m *
    wind_speed_10m *
    @math.pow(sc / 660.0, -0.5)
  kw_cm_hr * 0.24
}

///|
pub fn o2_solubility_saturation(
  temperature_c : Double,
  salinity_psu : Double,
) -> Double {
  let t_k = temperature_c + 273.15
  let ts = (298.15 - t_k) / t_k

  let a0 = 2.00907
  let a1 = 3.22014
  let a2 = 4.05010
  let a3 = 4.94457
  let a4 = -0.256847
  let a5 = 3.88767

  let ln_c0 = a0 +
    a1 * ts +
    a2 * ts * ts +
    a3 * ts * ts * ts +
    a4 * ts * ts * ts * ts +
    a5 * ts * ts * ts * ts * ts
  let c0 = @math.exp(ln_c0)

  let b0 = -0.00624097
  let b1 = -0.00693498
  let b2 = -0.00690358
  let sal_corr = @math.exp(salinity_psu * (b0 + b1 * ts + b2 * ts * ts))

  c0 * sal_corr * 44.66
}

///|
pub fn air_sea_gas_flux(
  kw_m_day : Double,
  mld_m : Double,
  conc_surface : Double,
  conc_sat : Double,
) -> Double {
  if mld_m <= 0.0 {
    0.0
  } else {
    kw_m_day * (conc_sat - conc_surface) / mld_m
  }
}

///|
pub fn sinking_particle_flux(
  sinking_velocity_m_day : Double,
  detritus_conc : Double,
  box_height_m : Double,
) -> Double {
  if box_height_m <= 0.0 {
    0.0
  } else {
    sinking_velocity_m_day * detritus_conc / box_height_m
  }
}
