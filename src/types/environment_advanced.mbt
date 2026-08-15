// Advanced Multi-Band Spectral Irradiance and Diurnal Environmental Forcing

///|
pub(all) struct SpectralIrradiance {
  red_par : Double // 600-700 nm (W/m^2)
  green_par : Double // 500-600 nm (W/m^2)
  blue_par : Double // 400-500 nm (W/m^2)
} derive(Debug)

///|
pub fn SpectralIrradiance::from_total_par(
  total_par : Double,
) -> SpectralIrradiance {
  // Approximate solar spectrum partitioning in seawater surface
  {
    red_par: total_par * 0.33,
    green_par: total_par * 0.34,
    blue_par: total_par * 0.33,
  }
}

///|
pub fn SpectralIrradiance::attenuate_at_depth(
  self : SpectralIrradiance,
  depth_m : Double,
  chl_conc : Double,
) -> SpectralIrradiance {
  // Wavelength-dependent attenuation coefficients kw (m^-1) and specific absorption k_chl
  let kw_red = 0.35
  let kw_green = 0.05
  let kw_blue = 0.02

  let k_chl_red = 0.020
  let k_chl_green = 0.008
  let k_chl_blue = 0.015

  let att_red = @math.exp(-(kw_red + k_chl_red * chl_conc) * depth_m)
  let att_green = @math.exp(-(kw_green + k_chl_green * chl_conc) * depth_m)
  let att_blue = @math.exp(-(kw_blue + k_chl_blue * chl_conc) * depth_m)

  {
    red_par: self.red_par * att_red,
    green_par: self.green_par * att_green,
    blue_par: self.blue_par * att_blue,
  }
}

///|
pub fn SpectralIrradiance::total(self : SpectralIrradiance) -> Double {
  self.red_par + self.green_par + self.blue_par
}

///|
pub fn diurnal_wind_speed(
  base_wind_speed : Double,
  hour_of_day : Double,
) -> Double {
  // Diurnal wind speed variability driven by sea-breeze circulation
  let pi = 3.141592653589793
  let phase = (hour_of_day - 14.0) * 2.0 * pi / 24.0
  let factor = 1.0 + 0.3 * @math.cos(phase)
  let wind = base_wind_speed * factor
  if wind < 0.5 {
    0.5
  } else {
    wind
  }
}
