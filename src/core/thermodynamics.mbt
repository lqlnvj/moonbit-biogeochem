// Seawater Physical Thermodynamics and Transport Properties

///|
pub fn seawater_density_eos80(
  temperature_c : Double,
  salinity_psu : Double,
) -> Double {
  // UNESCO (1981) Equation of State for Seawater EOS-80 at 1 atm surface pressure (kg/m^3)
  let t = temperature_c
  let s = salinity_psu

  // Pure water density rho0
  let a0 = 999.842594
  let a1 = 6.793952e-2
  let a2 = -9.095290e-3
  let a3 = 1.001685e-4
  let a4 = -1.120083e-6
  let a5 = 6.536332e-9
  let rho0 = a0 +
    a1 * t +
    a2 * t * t +
    a3 * t * t * t +
    a4 * t * t * t * t +
    a5 * t * t * t * t * t

  // Salinity correction terms
  let b0 = 8.24493e-1
  let b1 = -4.0899e-3
  let b2 = 7.6438e-5
  let b3 = -8.2467e-7
  let b4 = 5.3875e-9
  let c0 = -5.72466e-3
  let c1 = 1.0227e-4
  let c2 = -1.6546e-6
  let d0 = 4.8314e-4

  let s_factor = (
      b0 + b1 * t + b2 * t * t + b3 * t * t * t + b4 * t * t * t * t
    ) *
    s
  let s32_factor = (c0 + c1 * t + c2 * t * t) * @math.pow(s, 1.5)
  let s2_factor = d0 * s * s

  rho0 + s_factor + s32_factor + s2_factor
}

///|
pub fn o2_molecular_diffusivity(temperature_c : Double) -> Double {
  // Molecular diffusion coefficient of O2 in seawater (m^2/day)
  // Wilke and Chang (1955) approximation
  let t_k = temperature_c + 273.15
  let d0 = 1.17e-9 * (t_k / 298.15) // m^2/s
  // Convert m^2/s to m^2/day
  d0 * 86400.0
}

///|
pub fn co2_molecular_diffusivity(temperature_c : Double) -> Double {
  // Molecular diffusion coefficient of CO2 in seawater (m^2/day)
  let t_k = temperature_c + 273.15
  let d0 = 0.97e-9 * (t_k / 298.15)
  d0 * 86400.0
}
