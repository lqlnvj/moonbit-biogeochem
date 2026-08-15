// Advanced Unit Converter Matrix and Scale Transformations for Oceanography

///|
pub struct UnitConverter {
  name : String
} derive(Debug)

///|
pub fn UnitConverter::new() -> UnitConverter {
  { name: "Oceanographic Standard Unit Converter" }
}

///|
pub fn convert_mmol_n_m3_to_mg_chl_m3(
  mmol_n : Double,
  c_n_ratio : Double,
  chl_c_ratio : Double,
) -> Double {
  // Converts Nitrogen concentration (mmol N/m^3) to Chlorophyll-a (mg Chl/m^3)
  // 1 mmol N = 14.0067 mg N
  // Carbon = mmol N * (C:N ratio) * 12.011 mg C/mmol C
  // Chl = mg C * (Chl:C ratio)
  if mmol_n <= 0.0 {
    0.0
  } else {
    let mg_c = mmol_n * c_n_ratio * 12.011
    mg_c * chl_c_ratio
  }
}

///|
pub fn convert_mmol_c_m3_to_uatm_co2(
  mmol_c : Double,
  temp_c : Double,
  sal_psu : Double,
) -> Double {
  // Approximate Henry's Law conversion for aqueous CO2 concentration to partial pressure (uatm)
  let t_k = temp_c + 273.15
  // Henry's constant K0 for CO2 (mmol / (m^3 * uatm))
  let k0 = 0.035 *
    @math.exp(2400.0 * (1.0 / t_k - 1.0 / 298.15)) *
    (1.0 - 0.001 * sal_psu)
  if k0 <= 0.0 {
    400.0
  } else {
    mmol_c / k0
  }
}

///|
pub fn convert_dbar_to_depth_m(
  pressure_dbar : Double,
  latitude_deg : Double,
) -> Double {
  // Unesco (1983) formula for pressure to depth conversion
  let pi = 3.141592653589793
  let lat_rad = latitude_deg * pi / 180.0
  let sin_lat = @math.sin(lat_rad)
  let g = 9.780318 *
    (
      1.0 +
      5.2788e-3 * sin_lat * sin_lat +
      2.36e-5 * sin_lat * sin_lat * sin_lat * sin_lat
    )
  // Approximate depth = dbar * 1.0e4 / (density * g)
  pressure_dbar * 10000.0 / (1025.0 * g)
}

///|
pub fn convert_celsius_to_kelvin(celsius : Double) -> Double {
  celsius + 273.15
}

///|
pub fn convert_kelvin_to_celsius(kelvin : Double) -> Double {
  kelvin - 273.15
}

///|
pub fn convert_per_day_to_per_hour(rate_day : Double) -> Double {
  rate_day / 24.0
}

///|
pub fn convert_per_hour_to_per_day(rate_hour : Double) -> Double {
  rate_hour * 24.0
}
