// Environmental Forcing and Ambient Ocean Conditions

pub(all) struct EnvironmentForcing {
  time_day : Double
  temperature : Double // Celsius
  salinity : Double    // PSU
  surface_par : Double // W/m^2 Surface Photosynthetically Active Radiation
  mld : Double         // Mixed Layer Depth (m)
  kz : Double          // Vertical diffusivity (m^2/day)
} derive(Debug, Eq)

pub fn EnvironmentForcing::default_surface() -> EnvironmentForcing {
  {
    time_day: 0.0,
    temperature: 18.0,
    salinity: 35.0,
    surface_par: 150.0,
    mld: 30.0,
    kz: 1.0,
  }
}

pub fn EnvironmentForcing::seasonal_forcing(day_of_year : Double, latitude_deg : Double) -> EnvironmentForcing {
  // Trigonometric approximation of seasonal PAR and Sea Surface Temperature (SST)
  let pi = 3.141592653589793
  let rad = latitude_deg * pi / 180.0
  let day_angle = (day_of_year - 80.0) * 2.0 * pi / 365.0
  
  // Seasonal temperature variation
  let temp_mean = 15.0 + 5.0 * (1.0 - rad.abs() / (pi / 2.0))
  let temp_amp = 4.0 * (rad / (pi / 2.0)).abs()
  let temp = temp_mean + temp_amp * @math.sin(day_angle - 0.5)
  
  // Seasonal PAR variation
  let par_max = 250.0 + 50.0 * @math.cos(day_angle)
  let par = if par_max < 10.0 { 10.0 } else { par_max }
  
  // Seasonal MLD dynamics (deeper in winter, shallower in summer)
  let mld = 40.0 + 30.0 * @math.cos(day_angle + pi)
  let mld_clamped = if mld < 10.0 { 10.0 } else { mld }
  
  {
    time_day: day_of_year,
    temperature: temp,
    salinity: 35.0,
    surface_par: par,
    mld: mld_clamped,
    kz: 0.5 + 0.5 * @math.sin(day_angle).abs(),
  }
}

pub fn EnvironmentForcing::par_at_depth(self : EnvironmentForcing, depth_m : Double, kw : Double, k_phyto : Double, phyto_conc : Double) -> Double {
  // Beer-Lambert law for light attenuation with self-shading by phytoplankton
  let total_extinction = kw + k_phyto * phyto_conc
  self.surface_par * @math.exp(-total_extinction * depth_m)
}
